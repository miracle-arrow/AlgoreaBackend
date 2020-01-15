package database

import (
	"reflect"
	"regexp"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAnswerStore_WithMethods(t *testing.T) {
	tests := []struct {
		name          string
		expectedQuery string
	}{
		{
			name:          "WithUsers",
			expectedQuery: "SELECT `answers`.* FROM `answers` JOIN users ON users.group_id = answers.author_id",
		},
		{
			name: "WithAttempts",
			expectedQuery: "SELECT `answers`.* FROM `answers` " +
				"JOIN attempts ON attempts.id = answers.attempt_id",
		},
		{
			name: "WithItems",
			expectedQuery: "SELECT `answers`.* FROM `answers` " +
				"JOIN attempts ON attempts.id = answers.attempt_id " +
				"JOIN items ON items.id = attempts.item_id",
		},
	}
	for _, testCase := range tests {
		testCase := testCase
		t.Run(testCase.name, func(t *testing.T) {
			db, mock := NewDBMock()
			defer func() { _ = db.Close() }()

			mock.ExpectQuery("^" + regexp.QuoteMeta(testCase.expectedQuery) + "$").
				WillReturnRows(mock.NewRows([]string{"id"}))

			store := NewDataStore(db).Answers()
			resultValue := reflect.ValueOf(store).MethodByName(testCase.name).Call([]reflect.Value{})[0]
			newStore := resultValue.Interface().(*AnswerStore)

			assert.NotEqual(t, store, newStore)
			assert.Equal(t, "answers", newStore.DataStore.tableName)

			var result []interface{}
			err := newStore.Scan(&result).Error()
			assert.NoError(t, err)
			assert.NoError(t, mock.ExpectationsWereMet())
		})
	}
}
