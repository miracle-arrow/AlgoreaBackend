package database

import (
	"fmt"

	"github.com/France-ioi/AlgoreaBackend/app/logging"
	"github.com/France-ioi/AlgoreaBackend/app/types"
)

// ItemStore implements database operations on items
type ItemStore struct {
	*DataStore
}

// ItemAccessDetails represents access rights for an item
type ItemAccessDetails struct {
	// MAX(groups_items.bCachedFullAccess)
	FullAccess       bool  `sql:"column:fullAccess" json:"full_access"`
	// MAX(groups_items.bCachedPartialAccess)
	PartialAccess    bool  `sql:"column:partialAccess" json:"partial_access"`
	// MAX(groups_items.bCachedGrayAccess)
	GrayedAccess     bool  `sql:"column:grayedAccess" json:"grayed_access"`
	// MAX(groups_items.bCachedAccessSolutions)
	AccessSolutions  bool  `sql:"column:accessSolutions" json:"access_solutions"`
}

type itemAccessDetailsWithID struct {
	ItemID        int64 `sql:"column:idItem"`
	ItemAccessDetails
}

// Item matches the content the `items` table
type Item struct {
	ID                types.Int64  `sql:"column:ID"`
	Type              types.String `sql:"column:sType"`
	DefaultLanguageID types.Int64  `sql:"column:idDefaultLanguage"`
	TeamsEditable     types.Bool   `sql:"column:bTeamsEditable"`
	NoScore           types.Bool   `sql:"column:bNoScore"`
	Version           int64        `sql:"column:iVersion"` // use Go default in DB (to be fixed)
}

// RawNavigationItem represents one row of a navigation subtree returned from the DB
type RawNavigationItem struct {
	// items
	ID                		int64    `sql:"column:ID"`
	Type              		string   `sql:"column:sType"`
	TransparentFolder 		bool	   `sql:"column:bTransparentFolder"`
	// whether items.idItemUnlocked is empty
	HasUnlockedItems  		bool     `sql:"column:hasUnlockedItems"`
	AccessRestricted  		bool  	 `sql:"column:bAccessRestricted"`

	// title (from items_strings) in the user’s default language or (if not available) default language of the item
	Title         				string   `sql:"column:sTitle"`

	// from users_items for current user
	UserScore 						  float32	 `sql:"column:iScore"`
	UserValidated 				  bool	   `sql:"column:bValidated"`
	UserFinished					  bool	   `sql:"column:bFinished"`
	UserKeyObtained 			  bool 	   `sql:"column:bKeyObtained"`
	UserSubmissionsAttempts int64    `sql:"column:nbSubmissionsAttempts"`
	UserStartDate           string   `sql:"column:sStartDate"` // iso8601 str
	UserValidationDate      string   `sql:"column:sValidationDate"` // iso8601 str
	UserFinishDate          string   `sql:"column:sFinishDate"` // iso8601 str

	// items_items
	IDItemParent					int64    `sql:"column:idItemParent"`
	Order 						    int64 	 `sql:"column:iChildOrder"`

	*ItemAccessDetails
}

func (s *ItemStore) tableName() string {
	return "items"
}

func (s *ItemStore) visible(user AuthUser) DB {
	groupItemsPerms := s.GroupItems().
		MatchingUserAncestors(user).
		Select("idItem, MAX(bCachedFullAccess) AS fullAccess, MAX(bCachedPartialAccess) AS partialAccess, MAX(bCachedGrayedAccess) AS grayedAccess").
		Group("idItem")

	return s.All().
		Joins("JOIN ? as visible ON visible.idItem = items.ID", groupItemsPerms.SubQuery()).
		Where("fullAccess > 0 OR partialAccess > 0 OR grayedAccess > 0")
}

func (s *ItemStore) visibleByID(user AuthUser, itemID int64) DB {
	return s.visible(user).Where("items.ID = ?", itemID)
}

func (s *ItemStore) visibleChildrenOfID(user AuthUser, itemID int64) DB {
	return s.
		visible(user).
		Joins("JOIN ? ii ON items.ID=idItemChild", s.ItemItems().All().SubQuery()).
		Where("ii.idItemParent = ?", itemID)
}

func (s *ItemStore) visibleGrandChildrenOfID(user AuthUser, itemID int64) DB {
	return s.
		visible(user).                                                                             // visible items are the leaves (potential grandChildren)
		Joins("JOIN ? ii1 ON items.ID = ii1.idItemChild", s.ItemItems().All().SubQuery()).         // get their parents' IDs (ii1)
		Joins("JOIN ? ii2 ON ii2.idItemChild = ii1.idItemParent", s.ItemItems().All().SubQuery()). // get their grand parents' IDs (ii2)
		Where("ii2.idItemParent = ?", itemID)
}

// GetRawNavigationData reads a navigation subtree from the DB and returns an array of RawNavigationItem's
func (s *ItemStore) GetRawNavigationData(rootID int64, userID, userLanguageID int64, user AuthUser) (*[]RawNavigationItem, error) {
	var result []RawNavigationItem

	// This query can be simplified if we add a column for relation degrees into `items_ancestors`

	itemQ := s.visibleByID(user, rootID).Select("items.ID, items.sType, items.bTransparentFolder, items.idItemUnlocked, items.idDefaultLanguage, NULL AS idItemParent, NULL AS idItemGrandparent, NULL AS iChildOrder, NULL AS bAccessRestricted, fullAccess, partialAccess, grayedAccess")
	childrenQ := s.visibleChildrenOfID(user, rootID).Select("items.ID, items.sType, items.bTransparentFolder, items.idItemUnlocked, items.idDefaultLanguage,	idItemParent, NULL AS idItemGrandparent, iChildOrder, bAccessRestricted, fullAccess, partialAccess, grayedAccess")
	gChildrenQ := s.visibleGrandChildrenOfID(user, rootID).Select("items.ID, items.sType, items.bTransparentFolder, items.idItemUnlocked, items.idDefaultLanguage, ii1.idItemParent, ii2.idItemParent AS idItemGrandparent, ii1.iChildOrder, ii1.bAccessRestricted, fullAccess, partialAccess, grayedAccess")

	query := s.Raw(
		`
		SELECT union_table.ID, union_table.sType, union_table.bTransparentFolder,
			COALESCE(union_table.idItemUnlocked, '')<>'' as hasUnlockedItems,
			COALESCE(ustrings.sTitle, dstrings.sTitle) AS sTitle,
			users_items.iScore AS iScore, users_items.bValidated AS bValidated,
			users_items.bFinished AS bFinished, users_items.bKeyObtained AS bKeyObtained,
			users_items.nbSubmissionsAttempts AS nbSubmissionsAttempts,
			users_items.sStartDate AS sStartDate, users_items.sValidationDate AS sValidationDate,
			users_items.sFinishDate AS sFinishDate,
			union_table.iChildOrder AS iChildOrder,
			union_table.bAccessRestricted,
			union_table.idItemParent AS idItemParent,
			union_table.fullAccess, union_table.partialAccess, union_table.grayedAccess
			FROM (? UNION (?) UNION (?)) union_table

			LEFT JOIN users_items ON users_items.idItem=union_table.ID AND users_items.idUser=?

			LEFT JOIN items_strings dstrings FORCE INDEX (idItem)
			 ON dstrings.idItem=union_table.ID AND dstrings.idLanguage=union_table.idDefaultLanguage

			LEFT JOIN items_strings ustrings ON ustrings.idItem=union_table.ID AND ustrings.idLanguage=?

			ORDER BY idItemGrandparent, idItemParent, iChildOrder`,
		itemQ.Query(), childrenQ.Query(), gChildrenQ.Query(), userID, userLanguageID)

	if err := query.Scan(&result).Error(); err != nil {
		return nil, err
	}
	return &result, nil
}

// RawItem represents one row of the getItem service data returned from the DB
type RawItem struct {
	// items
	ID                		 int64    `sql:"column:ID"`
	Type              		 string   `sql:"column:sType"`
	DisplayDetailsInParent bool	    `sql:"column:bDisplayDetailsInParent"`
	ValidationType         string   `sql:"column:sValidationType"`
	HasUnlockedItems  		 bool     `sql:"column:hasUnlockedItems"` // whether items.idItemUnlocked is empty
	ScoreMinUnlock         int64    `sql:"column:iScoreMinUnlock"`
	TeamMode               string   `sql:"column:sTeamMode"`
	TeamsEditable          bool	    `sql:"column:bTeamsEditable"`
	TeamMaxMembers         int64    `sql:"column:iTeamMaxMembers"`
	HasAttempts            bool	    `sql:"column:bHasAttempts"`
	AccessOpenDate         string   `sql:"column:sAccessOpenDate"` // iso8601 str
	Duration               string   `sql:"column:sDuration"`
	EndContestDate         string   `sql:"column:sEndContestDate"` // iso8601 str
	NoScore                bool     `sql:"column:bNoScore"`
	GroupCodeEnter         bool     `sql:"column:groupCodeEnter"`

	// root node only
	TitleBarVisible *bool   `sql:"column:bTitleBarVisible"`
	ReadOnly        *bool   `sql:"column:bReadOnly"`
	FullScreen      *string `sql:"column:sFullScreen"`
	ShowSource      *bool   `sql:"column:bShowSource"`
	ValidationMin   *int64  `sql:"column:iValidationMin"`
	ShowUserInfos   *bool   `sql:"column:bShowUserInfos"`
	ContestPhase    *string `sql:"column:sContestPhase"`
	URL             *string `sql:"column:sUrl"`          // only if not a chapter
	UsesAPI         *bool   `sql:"column:bUsesAPI"`      // only if not a chapter
	HintsAllowed    *bool   `sql:"column:bHintsAllowed"` // only if not a chapter

	// from items_strings: in the user’s default language or (if not available) default language of the item
	StringLanguageID  int64  `sql:"column:idLanguage"`
	StringTitle       string `sql:"column:sTitle"`
	StringImageURL    string `sql:"column:sImageUrl"`
	StringSubtitle    string `sql:"column:sSubtitle"`
	StringDescription string `sql:"column:sDescription"`
	StringEduComment  string `sql:"column:sEduComment"`

	// from users_items for current user
	UserActiveAttemptID     int64   `sql:"column:idAttemptActive"`
	UserScore               float32 `sql:"column:iScore"`
	UserSubmissionsAttempts int64   `sql:"column:nbSubmissionsAttempts"`
	UserValidated           bool    `sql:"column:bValidated"`
	UserFinished            bool    `sql:"column:bFinished"`
	UserKeyObtained         bool    `sql:"column:bKeyObtained"`
	UserHintsCached         int64   `sql:"column:nbHintsCached"`
	UserStartDate           string  `sql:"column:sStartDate"` // iso8601 str
	UserValidationDate      string  `sql:"column:sValidationDate"` // iso8601 str
	UserFinishDate          string   `sql:"column:sFinishDate"` // iso8601 str
	UserContestStartDate    string   `sql:"column:sContestStartDate"` // iso8601 str
	UserState               *string  `sql:"column:sState"` // only if not a chapter
	UserAnswer              *string  `sql:"column:sAnswer"` // only if not a chapter

	// items_items
	Order 						    int64 	 `sql:"column:iChildOrder"`
	Category 						  *string  `sql:"column:sCategory"`
	AlwaysVisible 				*bool    `sql:"column:bAlwaysVisible"`
	AccessRestricted 			*bool    `sql:"column:bAccessRestricted"`

	*ItemAccessDetails
}

// GetRawItemData reads data needed by the getItem service from the DB and returns an array of RawItem's
func (s *ItemStore) GetRawItemData(rootID, userID, userLanguageID int64, user AuthUser) (*[]RawItem, error) {
	var result []RawItem

	// This query can be simplified if we add a column for relation degrees into `items_ancestors`
	if err := s.Raw(
		`SELECT
			union_table.ID,
			union_table.sType,
			union_table.bDisplayDetailsInParent,
			union_table.sValidationType,` +
			// idItemUnlocked is a comma-separated list of item IDs which will be unlocked if this item is validated
			// Here we consider both NULL and an empty string as FALSE
			`COALESCE(union_table.idItemUnlocked, '')<>'' as hasUnlockedItems,
			union_table.iScoreMinUnlock,
			union_table.sTeamMode,
			union_table.bTeamsEditable,
			union_table.iTeamMaxMembers,
			union_table.bHasAttempts,
			union_table.sAccessOpenDate,
			union_table.sDuration,
			union_table.sEndContestDate,
			union_table.bNoScore,
			union_table.groupCodeEnter,

			COALESCE(ustrings.idLanguage, dstrings.idLanguage) AS idLanguage,
			IF(ustrings.idLanguage IS NULL, dstrings.sTitle, ustrings.sTitle) AS sTitle,
			IF(ustrings.idLanguage IS NULL, dstrings.sImageUrl, ustrings.sImageUrl) AS sImageUrl,
			IF(ustrings.idLanguage IS NULL, dstrings.sSubtitle, ustrings.sSubtitle) AS sSubtitle,
			IF(ustrings.idLanguage IS NULL, dstrings.sDescription, ustrings.sDescription) AS sDescription,
			IF(ustrings.idLanguage IS NULL, dstrings.sEduComment, ustrings.sEduComment) AS sEduComment,

			users_items.idAttemptActive AS idAttemptActive,
			users_items.iScore AS iScore,
			users_items.nbSubmissionsAttempts AS nbSubmissionsAttempts,
			users_items.bValidated AS bValidated,
			users_items.bFinished AS bFinished,
			users_items.bKeyObtained AS bKeyObtained,
			users_items.nbHintsCached AS nbHintsCached,
			users_items.sStartDate AS sStartDate,
			users_items.sValidationDate AS sValidationDate,
			users_items.sFinishDate AS sFinishDate,
			users_items.sContestStartDate AS sContestStartDate,
			IF(union_table.sType <> 'Chapter', users_items.sState, NULL) as sState,
			users_items.sAnswer,

			union_table.iChildOrder AS iChildOrder,
			union_table.sCategory AS sCategory,
			union_table.bAlwaysVisible,
			union_table.bAccessRestricted, ` +
		  // inputItem only
			`union_table.bTitleBarVisible,
			union_table.bReadOnly,
			union_table.sFullScreen,
			union_table.bShowSource,
			union_table.iValidationMin,
			union_table.bShowUserInfos,
			union_table.sContestPhase,
			union_table.sUrl,
			union_table.bUsesAPI,
			union_table.bHintsAllowed,
			accessRights.fullAccess, accessRights.partialAccess, accessRights.grayedAccess, accessRights.accessSolutions
		FROM (
      SELECT
        items.ID AS ID,
			  items.sType,
			  items.bDisplayDetailsInParent,
			  items.sValidationType,
			  items.idItemUnlocked,
			  items.iScoreMinUnlock,
			  items.sTeamMode,
			  items.bTeamsEditable,
			  items.iTeamMaxMembers,
			  items.bHasAttempts,
			  items.sAccessOpenDate,
			  items.sDuration,
			  items.sEndContestDate,
			  items.bNoScore,
			  items.groupCodeEnter,
			  items.bTitleBarVisible,
			  items.bReadOnly,
			  items.sFullScreen,
			  items.bShowSource,
			  items.iValidationMin,
			  items.bShowUserInfos,
			  items.sContestPhase,
			  items.sUrl,
			  IF(items.sType <> 'Chapter', items.bUsesAPI, NULL) AS bUsesAPI,
			  IF(items.sType <> 'Chapter', items.bHintsAllowed, NULL) AS bHintsAllowed,
			  items.idDefaultLanguage,
			  NULL AS iChildOrder, NULL AS sCategory, NULL AS bAlwaysVisible, NULL AS bAccessRestricted
			FROM items WHERE items.ID=?
      UNION ALL
			SELECT
        items.ID AS ID, items.sType, items.bDisplayDetailsInParent,
			  items.sValidationType, items.idItemUnlocked,
			  items.iScoreMinUnlock,
			  items.sTeamMode,
			  items.bTeamsEditable,
			  items.iTeamMaxMembers,
			  items.bHasAttempts,
			  items.sAccessOpenDate,
			  items.sDuration,
			  items.sEndContestDate,
			  items.bNoScore,
			  items.groupCodeEnter,
			  NULL AS bTitleBarVisible,
			  NULL AS bReadOnly,
			  NULL AS sFullScreen,
			  NULL AS bShowSource,
			  NULL AS iValidationMin,
			  NULL AS bShowUserInfos,
			  NULL AS sContestPhase,
			  NULL AS sUrl,
			  NULL AS bUsesAPI,
			  NULL AS bHintsAllowed,
			  items.idDefaultLanguage,
			  iChildOrder, sCategory, bAlwaysVisible, bAccessRestricted
      FROM items
			JOIN items_items ON items.ID=idItemChild AND idItemParent=?
    ) union_table
    LEFT JOIN users_items ON users_items.idItem=union_table.ID AND users_items.idUser=?
    LEFT JOIN items_strings dstrings FORCE INDEX (idItem)
    ON dstrings.idItem=union_table.ID AND dstrings.idLanguage=union_table.idDefaultLanguage
    LEFT JOIN items_strings ustrings ON ustrings.idItem=union_table.ID AND ustrings.idLanguage=?
    JOIN ? accessRights on accessRights.idItem=union_table.ID AND (fullAccess>0 OR partialAccess>0 OR grayedAccess>0)
    ORDER BY iChildOrder`,
		rootID, rootID, userID, userLanguageID, s.accessRights(user).SubQuery()).Scan(&result).Error(); err != nil {
		return nil, err
	}
	return &result, nil
}

func (s *ItemStore) accessRights(user AuthUser) DB {
	return s.GroupItems().MatchingUserAncestors(user).
		Select(
			"idItem, MAX(bCachedFullAccess) AS fullAccess, " +
				"MAX(bCachedPartialAccess) AS partialAccess, " +
				"MAX(bCachedGrayedAccess) AS grayedAccess, " +
				"MAX(bCachedAccessSolutions) AS accessSolutions").
		Group("idItem")
}

// Insert does a INSERT query in the given table with data that may contain types.* types
func (s *ItemStore) Insert(data *Item) error {
	return s.insert(s.tableName(), data)
}

// ByID returns a composable query of items filtered by itemID
func (s *ItemStore) ByID(itemID int64) DB {
	return s.All().Where("items.ID = ?", itemID)
}

// All creates a composable query without filtering
func (s *ItemStore) All() DB {
	return s.table(s.tableName())
}

// HasManagerAccess returns whether the user has manager access to all the given item_id's
// It is assumed that the `OwnerAccess` implies manager access
func (s *ItemStore) HasManagerAccess(user AuthUser, itemID int64) (found bool, allowed bool, err error) {

	var dbRes []struct {
		ItemID        int64 `sql:"column:idItem"`
		ManagerAccess bool  `sql:"column:bManagerAccess"`
		OwnerAccess   bool  `sql:"column:bOwnerAccess"`
	}

	db := s.GroupItems().MatchingUserAncestors(user).
		Select("idItem, bManagerAccess, bOwnerAccess").
		Where("idItem = ?", itemID).
		Scan(&dbRes)
	if db.Error() != nil {
		return false, false, db.Error()
	}
	if len(dbRes) != 1 {
		return false, false, nil
	}
	item := dbRes[0]
	return true, item.ManagerAccess || item.OwnerAccess, nil
}

// IsValidHierarchy gets an ordered set of item ids and returns whether they forms a valid item hierarchy path from a root
func (s *ItemStore) IsValidHierarchy(ids []int64) (bool, error) {
	if len(ids) == 0 {
		return false, nil
	}

	if valid, err := s.isRootItem(ids[0]); !valid || err != nil {
		return valid, err
	}

	if valid, err := s.isHierarchicalChain(ids); !valid || err != nil {
		return valid, err
	}

	return true, nil
}

// ValidateUserAccess gets a set of item ids and returns whether the given user is authorized to see them all
func (s *ItemStore) ValidateUserAccess(user AuthUser, itemIDs []int64) (bool, error) {
	accessDetails, err := s.getAccessDetailsForIDs(user, itemIDs)
	if err != nil {
		logging.Logger.Infof("User access rights loading failed: %v", err)
		return false, err
	}

	if err := checkAccess(itemIDs, accessDetails); err != nil {
		logging.Logger.Infof("checkAccess %v %v", itemIDs, accessDetails)
		logging.Logger.Infof("User access validation failed: %v", err)
		return false, nil
	}
	return true, nil
}

// getAccessDetailsForIDs returns access details for given item IDs and the given user
func (s *ItemStore) getAccessDetailsForIDs(user AuthUser, itemIDs []int64) ([]itemAccessDetailsWithID, error) {
	var accessDetails []itemAccessDetailsWithID
	db := s.GroupItems().MatchingUserAncestors(user).
		Select("idItem, MAX(bCachedFullAccess) AS fullAccess, MAX(bCachedPartialAccess) AS partialAccess, " +
			"MAX(bCachedGrayedAccess) AS grayedAccess, MAX(bCachedAccessSolutions) AS accessSolutions").
		Where("groups_items.idItem IN (?)", itemIDs).
		Group("idItem").Scan(&accessDetails)
	if err := db.Error(); err != nil {
		return nil, err
	}
	return accessDetails, nil
}

// GetAccessDetailsMapForIDs returns access details for given item IDs and the given user as a map (item_id->details)
func (s *ItemStore) GetAccessDetailsMapForIDs(user AuthUser, itemIDs []int64) (map[int64]ItemAccessDetails, error) {
	accessDetails, err := s.getAccessDetailsForIDs(user, itemIDs)
	if err != nil {
		return nil, err
	}
	accessDetailsMap := make(map[int64]ItemAccessDetails, len(accessDetails))
	for _, row := range accessDetails {
		accessDetailsMap[row.ItemID] = ItemAccessDetails{
			FullAccess: row.FullAccess,
			PartialAccess: row.PartialAccess,
			GrayedAccess: row.GrayedAccess,
			AccessSolutions: row.AccessSolutions,
		}
	}
	return accessDetailsMap, nil
}

// checkAccess checks if the user has access to all items:
// - user has to have full access to all items
// OR
// - user has to have full access to all but last, and grayed access to that last item.
func checkAccess(itemIDs []int64, accDets []itemAccessDetailsWithID) error {
	for i, id := range itemIDs {
		last := i == len(itemIDs)-1
		if err := checkAccessForID(id, last, accDets); err != nil {
			return err
		}
	}
	return nil
}

func checkAccessForID(id int64, last bool, accDets []itemAccessDetailsWithID) error {
	for _, res := range accDets {
		if res.ItemID != id {
			continue
		}
		if res.FullAccess || res.PartialAccess {
			// OK, user has full access.
			return nil
		}
		if res.GrayedAccess && last {
			// OK, user has grayed access on the last item.
			return nil
		}
		return fmt.Errorf("not enough perm on item_id %d", id)
	}

	// no row matching this item_id
	return fmt.Errorf("not visible item_id %d", id)
}

func (s *ItemStore) isRootItem(id int64) (bool, error) {
	count := 0
	if err := s.ByID(id).Where("sType='Root'").Count(&count).Error(); err != nil {
		return false, err
	}
	if count == 0 {
		return false, nil
	}
	return true, nil
}

func (s *ItemStore) isHierarchicalChain(ids []int64) (bool, error) {
	if len(ids) == 0 {
		return false, nil
	}

	if len(ids) == 1 {
		return true, nil
	}

	db := s.ItemItems().All()
	previousID := ids[0]
	for index, id := range ids {
		if index == 0 {
			continue
		}

		db = db.Or("idItemParent=? AND idItemChild=?", previousID, id)
		previousID = id
	}

	count := 0
	// For now, we don’t have a unique key for the pair ('idItemParent' and 'idItemChild') and
	// theoritically it’s still possible to have multiple rows with the same pair
	// of 'idItemParent' and 'idItemChild'.
	// The “Group(...)” here resolves the issue.
	if err := db.Group("idItemParent, idItemChild").Count(&count).Error(); err != nil {
		return false, err
	}

	if count != len(ids)-1 {
		return false, nil
	}

	return true, nil
}
