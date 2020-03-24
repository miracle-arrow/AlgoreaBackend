package items

import (
	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// rawNavigationItem represents one row of a navigation subtree returned from the DB
type rawNavigationItem struct {
	// items
	ID                     int64
	Type                   string
	ContentViewPropagation string

	// title (from items_strings) in the user’s default language or (if not available) default language of the item
	Title *string

	// max from results of the current user
	UserBestScore float32 `sql:"column:best_score"`
	UserValidated bool    `sql:"column:validated"`

	// items_items
	ParentItemID int64
	Order        int32 `sql:"column:child_order"`

	CanViewGeneratedValue int

	ItemGrandparentID *int64
}

// getRawNavigationData reads a navigation subtree from the DB and returns an array of rawNavigationItem's
func getRawNavigationData(dataStore *database.DataStore, rootID, groupID int64, user *database.User) []rawNavigationItem {
	var result []rawNavigationItem
	items := dataStore.Items()

	// This query can be simplified if we add a column for relation degrees into `items_ancestors`

	commonAttributes := "items.id, items.type, items.default_language_tag, " +
		"can_view_generated_value"
	itemQ := items.VisibleByID(groupID, rootID).Select(
		commonAttributes + ", NULL AS parent_item_id, NULL AS item_grandparent_id, NULL AS child_order, NULL AS content_view_propagation")
	service.MustNotBeError(itemQ.Error())
	childrenQ := items.VisibleChildrenOfID(groupID, rootID).Select(
		commonAttributes + ",	parent_item_id, NULL AS item_grandparent_id, child_order, content_view_propagation")
	service.MustNotBeError(childrenQ.Error())
	gChildrenQ := items.VisibleGrandChildrenOfID(groupID, rootID).Select(
		commonAttributes + ", ii1.parent_item_id, ii2.parent_item_id AS item_grandparent_id, ii1.child_order, ii1.content_view_propagation")

	service.MustNotBeError(gChildrenQ.Error())
	itemThreeGenQ := itemQ.Union(childrenQ.QueryExpr()).Union(gChildrenQ.QueryExpr())
	service.MustNotBeError(itemThreeGenQ.Error())

	query := dataStore.Raw(`
		SELECT items.id, items.type,
			COALESCE(user_strings.title, default_strings.title) AS title,
			IFNULL(best_scores.best_score, 0) AS best_score,
			IFNULL(best_scores.validated, 0) AS validated,
			items.child_order AS child_order,
			items.content_view_propagation,
			items.parent_item_id AS parent_item_id,
			items.item_grandparent_id AS item_grandparent_id,
			items.can_view_generated_value
		FROM ? items`, itemThreeGenQ.SubQuery()).
		JoinsUserAndDefaultItemStrings(user).
		Joins(`
			LEFT JOIN LATERAL (
				SELECT MAX(results.score_computed) AS best_score,
				       MAX(results.validated) AS validated
				FROM results
				WHERE results.item_id = items.id AND results.participant_id = ?
				GROUP BY results.participant_id, results.item_id
			) AS best_scores ON 1`, groupID).
		Order("item_grandparent_id, parent_item_id, child_order")

	service.MustNotBeError(query.Scan(&result).Error())
	return result
}
