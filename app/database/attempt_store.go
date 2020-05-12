package database

import (
	"github.com/jinzhu/gorm"
)

// AttemptStore implements database operations on `attempts`
type AttemptStore struct {
	*DataStore
}

// CreateNew creates a new attempt (with id > 0) with parent_attempt_id = parentAttemptID and a new result.
// It also sets attempts.created_at, results.started_at, results.latest_activity_at, so the result should be propagated.
func (s *AttemptStore) CreateNew(participantID, parentAttemptID, itemID, creatorID int64) (attemptID int64, err error) {
	s.mustBeInTransaction()
	recoverPanics(&err)

	mustNotBeError(s.InsertMap(map[string]interface{}{
		"id": gorm.Expr("(SELECT * FROM ? AS max_attempt)", s.Attempts().Select("IFNULL(MAX(id)+1, 0)").
			Where("participant_id = ?", participantID).WithWriteLock().SubQuery()),
		"participant_id": participantID, "creator_id": creatorID,
		"parent_attempt_id": parentAttemptID, "root_item_id": itemID, "created_at": Now(),
	}))
	mustNotBeError(s.Where("participant_id = ?", participantID).PluckFirst("MAX(id)", &attemptID).Error())

	mustNotBeError(s.Results().InsertMap(map[string]interface{}{
		"participant_id": participantID, "attempt_id": attemptID, "item_id": itemID,
		"started_at": Now(), "latest_activity_at": Now(), "result_propagation_state": "to_be_propagated",
	}))
	return attemptID, nil
}

// GetAttemptParticipantIDIfUserHasAccess returns results.participant_id if:
//  1) the user has at least 'content' access to the item
//  2) the user is a member of results.participant_id or the user's group_id = results.participant_id
func (s *AttemptStore) GetAttemptParticipantIDIfUserHasAccess(
	attemptID, itemID int64, user *User) (found bool, participantID int64, err error) {
	recoverPanics(&err)
	mustNotBeError(err)
	usersGroupsQuery := s.GroupGroups().WhereUserIsMember(user).Select("parent_group_id")

	s.Results().Where("results.item_id = ? AND results.attempt_id = ?", itemID, attemptID).
		Joins("JOIN ? AS permissions ON results.item_id = permissions.item_id",
			s.Permissions().WithViewPermissionForUser(user, "content").
				Where("item_id = ?", itemID).SubQuery())
	err = s.Items().WhereUserHasViewPermissionOnItems(user, "content").
		Joins("JOIN results ON results.item_id = items.id AND results.attempt_id = ?", attemptID).
		Where("results.participant_id = ? OR results.participant_id IN ?",
			user.GroupID, usersGroupsQuery.SubQuery()).
		Where("items.id = ?", itemID).
		PluckFirst("results.participant_id", &participantID).Error()
	if gorm.IsRecordNotFoundError(err) {
		return false, 0, nil
	}
	mustNotBeError(err)
	return true, participantID, nil
}
