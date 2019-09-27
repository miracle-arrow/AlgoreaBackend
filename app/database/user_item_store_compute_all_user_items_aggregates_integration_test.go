// +build !unit

package database_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"

	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/testhelpers"
)

type aggregatesResultRow struct {
	ID                        int64
	LastActivityAt            *database.Time
	TasksTried                int64
	TasksWithHelp             int64
	TasksSolved               int64
	ChildrenValidated         int64
	AncestorsComputationState string
}

func TestUserItemStore_ComputeAllUserItems_Aggregates(t *testing.T) {
	db := testhelpers.SetupDBWithFixture("users_items_propagation/_common", "users_items_propagation/aggregates")
	defer func() { _ = db.Close() }()

	userItemStore := database.NewDataStore(db).UserItems()

	currentDate := time.Now().Round(time.Second).UTC()
	oldDate := currentDate.AddDate(-1, -1, -1)

	assert.NoError(t, userItemStore.Where("id=11").Updates(map[string]interface{}{
		"last_activity_at":   oldDate,
		"tasks_tried":        1,
		"tasks_with_help":    2,
		"tasks_solved":       3,
		"children_validated": 4,
		"validated":          1,
	}).Error())
	assert.NoError(t, userItemStore.Where("id=13").Updates(map[string]interface{}{
		"last_activity_at":   currentDate,
		"tasks_tried":        5,
		"tasks_with_help":    6,
		"tasks_solved":       7,
		"children_validated": 8,
	}).Error())
	assert.NoError(t, userItemStore.Where("id=14").Updates(map[string]interface{}{
		"last_activity_at":   nil,
		"tasks_tried":        9,
		"tasks_with_help":    10,
		"tasks_solved":       11,
		"children_validated": 12,
		"validated":          1,
	}).Error())

	err := userItemStore.InTransaction(func(s *database.DataStore) error {
		return s.UserItems().ComputeAllUserItems()
	})
	assert.NoError(t, err)

	expected := []aggregatesResultRow{
		{ID: 11, LastActivityAt: (*database.Time)(&oldDate), TasksTried: 1, TasksWithHelp: 2, TasksSolved: 3, ChildrenValidated: 4,
			AncestorsComputationState: "done"},
		{ID: 12, LastActivityAt: (*database.Time)(&currentDate), TasksTried: 1 + 5 + 9, TasksWithHelp: 2 + 6 + 10, TasksSolved: 3 + 7 + 11,
			ChildrenValidated: 2, AncestorsComputationState: "done"},
		{ID: 13, LastActivityAt: (*database.Time)(&currentDate), TasksTried: 5, TasksWithHelp: 6, TasksSolved: 7, ChildrenValidated: 8,
			AncestorsComputationState: "done"},
		{ID: 14, LastActivityAt: nil, TasksTried: 9, TasksWithHelp: 10, TasksSolved: 11, ChildrenValidated: 12,
			AncestorsComputationState: "done"},
		// another user
		{ID: 22, LastActivityAt: nil, AncestorsComputationState: "done"},
	}

	assertAggregatesEqual(t, userItemStore, expected)
}

func TestUserItemStore_ComputeAllUserItems_Aggregates_OnCommonData(t *testing.T) {
	db := testhelpers.SetupDBWithFixture("users_items_propagation/_common")
	defer func() { _ = db.Close() }()

	userItemStore := database.NewDataStore(db).UserItems()
	err := userItemStore.InTransaction(func(s *database.DataStore) error {
		return s.UserItems().ComputeAllUserItems()
	})
	assert.NoError(t, err)

	var result []aggregatesResultRow
	assert.NoError(t, userItemStore.
		Select("id, last_activity_at, tasks_tried, tasks_with_help, tasks_solved, children_validated, ancestors_computation_state").
		Scan(&result).Error())

	expected := []aggregatesResultRow{
		{ID: 11, AncestorsComputationState: "done"},
		{ID: 12, AncestorsComputationState: "done"},
		{ID: 22, AncestorsComputationState: "done"},
	}
	assertAggregatesEqual(t, userItemStore, expected)
}

func assertAggregatesEqual(t *testing.T, userItemStore *database.UserItemStore, expected []aggregatesResultRow) {
	var result []aggregatesResultRow
	assert.NoError(t, userItemStore.
		Select("id, last_activity_at, tasks_tried, tasks_with_help, tasks_solved, children_validated, ancestors_computation_state").
		Scan(&result).Error())
	assert.Equal(t, expected, result)
}
