package service

import (
	"database/sql/driver"
	"errors"
	"net/http"
	"regexp"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"

	"github.com/France-ioi/AlgoreaBackend/app/database"
)

func TestApplySorting(t *testing.T) {
	type args struct {
		urlParameters  string
		acceptedFields map[string]*FieldSortingParams
		defaultRules   string
	}
	tests := []struct {
		name             string
		args             args
		wantSQL          string
		wantSQLArguments []driver.Value
		wantAPIError     APIError
		shouldPanic      error
	}{
		{name: "sorting (default rules)",
			args: args{
				urlParameters: "",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
				defaultRules: "-name,id",
			},
			wantSQL:      "SELECT ID FROM `users` ORDER BY sName DESC, ID ASC",
			wantAPIError: NoError},
		{name: "sorting (request rules)",
			args: args{
				urlParameters: "?sort=name,-id",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
			},
			wantSQL:      "SELECT ID FROM `users` ORDER BY sName ASC, ID DESC",
			wantAPIError: NoError},
		{name: "repeated field",
			args: args{
				urlParameters: "?sort=name,name",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
				defaultRules: "-name,id",
			},
			wantAPIError: ErrInvalidRequest(errors.New(`a field cannot be a sorting parameter more than once: "name"`))},
		{name: "unallowed field",
			args: args{
				urlParameters: "?sort=class",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
				defaultRules: "-name,id",
			},
			wantAPIError: ErrInvalidRequest(errors.New(`unallowed field in sorting parameters: "class"`))},
		{name: "add id field",
			args: args{
				urlParameters: "",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
				},
				defaultRules: "-name",
			},
			wantSQL:          "SELECT ID FROM `users` ORDER BY sName DESC, ID ASC",
			wantSQLArguments: nil,
			wantAPIError:     NoError},
		{name: "no rules (adds id)",
			args: args{
				urlParameters: "",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
			},
			wantSQL:      "SELECT ID FROM `users` ORDER BY ID ASC",
			wantAPIError: NoError},
		{name: "sorting + paging",
			args: args{
				urlParameters: "?from.id=1&from.name=Joe&from.flag=1",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
					"flag": {ColumnName: "bFlag", FieldType: "bool"},
				},
				defaultRules: "-name,id,flag",
			},
			wantSQL:          "SELECT ID FROM `users` WHERE ((sName < ?) OR (sName = ? AND ID > ?) OR (sName = ? AND ID = ? AND bFlag > ?)) ORDER BY sName DESC, ID ASC, bFlag ASC",
			wantSQLArguments: []driver.Value{"Joe", "Joe", 1, "Joe", 1, true},
			wantAPIError:     NoError},
		{name: "wrong value in from.id field",
			args: args{
				urlParameters: "?from.id=abc&from.name=Joe",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
				defaultRules: "-name,id",
			},
			wantAPIError: ErrInvalidRequest(errors.New(`wrong value for from.id (should be int64)`))},
		{name: "one of the from. fields is skipped",
			args: args{
				urlParameters: "?from.id=2",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "string"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
				defaultRules: "-name,id",
			},
			wantAPIError: ErrInvalidRequest(errors.New(`all 'from' parameters (from.name, from.id) or none of them must be present`))},
		{name: "unsupported field type",
			args: args{
				urlParameters: "?from.name=Joe&from.id=2",
				acceptedFields: map[string]*FieldSortingParams{
					"name": {ColumnName: "sName", FieldType: "interface{}"},
					"id":   {ColumnName: "ID", FieldType: "int64"},
				},
				defaultRules: "-name,id",
			},
			shouldPanic: errors.New(`unsupported type "interface{}" for field "name"`)},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			defer func() {
				if p := recover(); p != nil {
					if tt.shouldPanic == nil {
						assert.Fail(t, "unexpected panic() was called with value %+v", p)
					} else {
						assert.Equal(t, tt.shouldPanic, p, "panic() value mismatched")
					}
				} else if tt.shouldPanic != nil {
					assert.Fail(t, "expected the test to panic(), but it did not")
				}
			}()
			db, dbMock := database.NewDBMock()
			defer func() { _ = db.Close() }()
			if tt.wantSQL != "" {
				dbMock.ExpectQuery("^" + regexp.QuoteMeta(tt.wantSQL) + "$").WithArgs(tt.wantSQLArguments...).
					WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(1))
			}

			request, _ := http.NewRequest("GET", "/"+tt.args.urlParameters, nil)
			query := db.Table("users").Select("ID")

			query, gotAPIError := ApplySortingAndPaging(request, query, tt.args.acceptedFields, tt.args.defaultRules)
			assert.Equal(t, tt.wantAPIError, gotAPIError)

			if gotAPIError == NoError {
				var result []struct{}
				query.Scan(&result)
			}

			assert.NoError(t, dbMock.ExpectationsWereMet())
		})
	}
}
