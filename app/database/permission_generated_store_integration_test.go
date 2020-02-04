// +build !unit

package database_test

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/testhelpers"
)

func TestPermissionGeneratedStore_TriggerAfterInsert_MarksAttemptsAsChanged(t *testing.T) {
	for _, test := range []struct {
		name            string
		groupID         int64
		itemID          int64
		canView         string
		expectedChanged []groupItemPair
	}{
		{
			name:            "make a parent item visible",
			groupID:         104,
			itemID:          2,
			canView:         "info",
			expectedChanged: []groupItemPair{{104, 3}, {105, 3}},
		},
		{
			name:            "make an ancestor item visible",
			groupID:         104,
			itemID:          1,
			canView:         "info",
			expectedChanged: []groupItemPair{{104, 2}, {104, 3}, {105, 2}, {105, 3}},
		},
		{
			name:            "make a parent item invisible",
			groupID:         104,
			itemID:          2,
			canView:         "none",
			expectedChanged: []groupItemPair{},
		},
		{
			name:            "make an item visible",
			groupID:         104,
			itemID:          3,
			canView:         "info",
			expectedChanged: []groupItemPair{},
		},
		{
			name:            "make a parent item visible for an expired membership",
			groupID:         108,
			itemID:          2,
			canView:         "none",
			expectedChanged: []groupItemPair{},
		},
	} {
		test := test
		t.Run(test.name, func(t *testing.T) {
			db := testhelpers.SetupDBWithFixtureString(groupGroupMarksAttemptsAsChangedFixture)
			defer func() { _ = db.Close() }()

			dataStore := database.NewDataStoreWithTable(db, "permissions_generated")
			assert.NoError(t, dataStore.InTransaction(func(store *database.DataStore) error {
				store.GroupGroups().CreateNewAncestors()
				return nil
			}))
			assert.NoError(t, dataStore.InsertMap(map[string]interface{}{
				"group_id": test.groupID, "item_id": test.itemID, "can_view_generated": test.canView,
			}))

			assertAttemptsMarkedAsChanged(t, dataStore, test.expectedChanged)
		})
	}
}

func TestPermissionGeneratedStore_TriggerAfterUpdate_MarksAttemptsAsChanged(t *testing.T) {
	for _, test := range []struct {
		name            string
		groupID         int64
		itemID          int64
		canView         string
		expectedChanged []groupItemPair
		noChanges       bool
		updateExisting  bool
	}{
		{
			name:            "make a parent item visible",
			groupID:         104,
			itemID:          2,
			canView:         "info",
			expectedChanged: []groupItemPair{{104, 3}, {105, 3}},
		},
		{
			name:            "make an ancestor item visible",
			groupID:         104,
			itemID:          1,
			canView:         "info",
			expectedChanged: []groupItemPair{{104, 2}, {104, 3}, {105, 2}, {105, 3}},
		},
		{
			name:            "make an ancestor item invisible",
			groupID:         108,
			itemID:          1,
			canView:         "none",
			expectedChanged: []groupItemPair{},
			updateExisting:  true,
		},
		{
			name:            "make an item visible",
			groupID:         104,
			itemID:          3,
			canView:         "info",
			expectedChanged: []groupItemPair{},
		},
		{
			name:           "switch ancestor from invisible to visible",
			groupID:        107,
			itemID:         1,
			canView:        "info",
			updateExisting: true,
			expectedChanged: []groupItemPair{
				{105, 2}, {105, 3},
				{107, 2}, {107, 3}},
		},
		{
			name:            "make a parent item visible for an expired membership",
			groupID:         108,
			itemID:          2,
			canView:         "info",
			expectedChanged: []groupItemPair{{108, 3}},
		},
		{
			name:            "no changes",
			groupID:         102,
			itemID:          1,
			canView:         "info",
			updateExisting:  true,
			expectedChanged: []groupItemPair{},
			noChanges:       true,
		},
	} {
		test := test
		t.Run(test.name, func(t *testing.T) {
			fixures := make([]string, 0, 2)
			if !test.updateExisting {
				fixures = append(fixures,
					fmt.Sprintf("permissions_generated: [{group_id: %d, item_id: %d}]", test.groupID, test.itemID))
			}
			fixures = append(fixures, groupGroupMarksAttemptsAsChangedFixture)
			db := testhelpers.SetupDBWithFixtureString(fixures...)
			defer func() { _ = db.Close() }()

			dataStore := database.NewDataStoreWithTable(db, "permissions_generated")
			assert.NoError(t, dataStore.InTransaction(func(store *database.DataStore) error {
				store.GroupGroups().CreateNewAncestors()
				return nil
			}))
			result := dataStore.Where("group_id = ?", test.groupID).
				Where("item_id = ?", test.itemID).UpdateColumn(map[string]interface{}{
				"can_view_generated": test.canView,
			})
			assert.NoError(t, result.Error())

			if test.noChanges {
				assert.Zero(t, result.RowsAffected())
			} else {
				assert.Equal(t, int64(1), result.RowsAffected())
			}
			assertAttemptsMarkedAsChanged(t, dataStore, test.expectedChanged)
		})
	}
}

func TestPermissionGeneratedStore_TriggerBeforeUpdate_RefusesToModifyGroupIDOrItemID(t *testing.T) {
	db := testhelpers.SetupDBWithFixtureString(`
		groups: [{id: 1}]
		items: [{id: 2, default_language_tag: 2}]
		permissions_generated: [{group_id: 1, item_id: 2, can_view_generated: none}]
	`)
	defer func() { _ = db.Close() }()

	const expectedErrorMessage = "Error 1644: Unable to change immutable " +
		"permissions_generated.group_id and/or permissions_generated.child_item_id"

	dataStore := database.NewDataStoreWithTable(db, "permissions_generated")
	result := dataStore.Where("group_id = 1 AND item_id = 2").
		UpdateColumn("group_id", 3)
	assert.EqualError(t, result.Error(), expectedErrorMessage)
	result = dataStore.Where("group_id = 1 AND item_id = 2").
		UpdateColumn("item_id", 3)
	assert.EqualError(t, result.Error(), expectedErrorMessage)
}