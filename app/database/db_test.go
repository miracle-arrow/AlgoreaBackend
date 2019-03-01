package database

import (
	"errors"
	"github.com/DATA-DOG/go-sqlmock"
	"github.com/France-ioi/AlgoreaBackend/app/types"
	"regexp"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestDB_inTransaction_NoErrors(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT 1 AS id").
		WillReturnRows(mock.NewRows([]string{"id"}).AddRow(int64(1)))
	mock.ExpectCommit()

	type resultStruct struct {
		ID int64 `sql:"column:id"`
	}
	var result []resultStruct
	err := db.inTransaction(func(db *DB) error {
		return db.Raw("SELECT 1 AS id").Scan(&result).Error()
	})

	assert.NoError(t, err)
	assert.Equal(t, []resultStruct{{1}}, result)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_inTransaction_DBError(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	expectedError := errors.New("some error")

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT 1").WillReturnError(expectedError)
	mock.ExpectRollback()

	gotError := db.inTransaction(func(db *DB) error {
		var result []interface{}
		return db.Raw("SELECT 1").Scan(&result).Error()
	})
	assert.Equal(t, expectedError, gotError)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_inTransaction_Panic(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	expectedError := errors.New("some error")

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT 1").WillReturnError(expectedError)
	mock.ExpectRollback()

	assert.Panics(t, func() { panic("") })
	assert.PanicsWithValue(t, expectedError.(interface{}), func() {
		_ = db.inTransaction(func(db *DB) error {
			var result []interface{}
			db.Raw("SELECT 1").Scan(&result)
			panic(expectedError)
		})
	})
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_inTransaction_ErrorOnRollback(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	expectedError := errors.New("some error")

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT 1").WillReturnError(expectedError)
	mock.ExpectRollback().WillReturnError(errors.New("rollback error"))

	assert.Panics(t, func() { panic("") })
	assert.PanicsWithValue(t, expectedError.(interface{}), func() {
		_ = db.inTransaction(func(db *DB) error {
			var result []interface{}
			db.Raw("SELECT 1").Scan(&result)
			panic(expectedError)
		})
	})
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_inTransaction_ErrorOnCommit(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	expectedError := errors.New("commit error")

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT 1").
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))
	mock.ExpectCommit().WillReturnError(expectedError)

	assert.Equal(t, expectedError, db.inTransaction(func(db *DB) error {
		var result []interface{}
		return db.Raw("SELECT 1").Scan(&result).Error()
	}))
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Limit(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery("SELECT \\* FROM `myTable` LIMIT 1").
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	db = db.Table("myTable")
	limitedDB := db.Limit(1)
	assert.NotEqual(t, limitedDB, db)
	assert.NoError(t, limitedDB.Error())

	var result []interface{}
	assert.NoError(t, limitedDB.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Or(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable` WHERE (ID = ?) OR (otherID = ?)")).
		WithArgs(1, 2).
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	db = db.Table("myTable").Where("ID = ?", 1)
	dbOr := db.Or("otherID = ?", 2)
	assert.NotEqual(t, dbOr, db)
	assert.NoError(t, dbOr.Error())

	var result []interface{}
	assert.NoError(t, dbOr.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Order(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable` ORDER BY `ID`")).
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	db = db.Table("myTable")
	dbOrder := db.Order("ID")
	assert.NotEqual(t, dbOrder, db)
	assert.NoError(t, dbOrder.Error())

	var result []interface{}
	assert.NoError(t, dbOrder.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Having(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable` HAVING (ID > 0)")).
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	db = db.Table("myTable")
	dbHaving := db.Having("ID > 0")
	assert.NotEqual(t, dbHaving, db)
	assert.NoError(t, dbHaving.Error())

	var result []interface{}
	assert.NoError(t, dbHaving.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Union(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable` UNION SELECT * FROM `otherTable`")).
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	db = db.Table("myTable")
	dbTwo := db.Table("otherTable")
	dbUnion := db.Union(dbTwo.QueryExpr())
	assert.NotEqual(t, dbUnion, db)
	assert.NotEqual(t, dbUnion, dbTwo)
	assert.NoError(t, dbUnion.Error())

	var result []interface{}
	assert.NoError(t, dbUnion.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_UnionAll(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable` UNION ALL SELECT * FROM `otherTable`")).
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	db = db.Table("myTable")
	dbTwo := db.Table("otherTable")
	dbUnionAll := db.UnionAll(dbTwo.QueryExpr())
	assert.NotEqual(t, dbUnionAll, db)
	assert.NotEqual(t, dbUnionAll, dbTwo)
	assert.NoError(t, dbUnionAll.Error())

	var result []interface{}
	assert.NoError(t, dbUnionAll.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Raw(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery("SELECT 1").
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	dbRaw := db.Raw("SELECT 1")
	assert.NotEqual(t, dbRaw, db)

	var result []interface{}
	assert.NoError(t, dbRaw.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Count(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT count(*) FROM `myTable`")).
		WillReturnRows(mock.NewRows([]string{"count"}).AddRow(1))

	db = db.Table("myTable")

	var result int
	countDB := db.Count(&result)

	assert.NotEqual(t, countDB, db)
	assert.NoError(t, countDB.Error())
	assert.Equal(t, 1, result)

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Take(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable` WHERE (ID = 1) LIMIT 1")).
		WillReturnRows(mock.NewRows([]string{"id"}).AddRow(1))

	db = db.Table("myTable")

	type resultType struct{ ID int }
	var result resultType
	countDB := db.Take(&result, "ID = 1")

	assert.NotEqual(t, countDB, db)
	assert.NoError(t, countDB.Error())
	assert.Equal(t, resultType{1}, result)

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_insert(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	type dataType struct {
		ID          int64        `sql:"column:ID"`
		Field       types.String `sql:"column:sField"`
		NullField   types.String `sql:"column:sNullField"`
		AbsentField types.String `sql:"column:sAbsentField"`
	}

	normalString := types.NewString("some value")
	normalString.Null = false
	normalString.Set = true

	nullString := types.NewString("")
	nullString.Null = true
	nullString.Set = true

	absentString := types.NewString("")
	absentString.Null = false
	absentString.Set = false

	dataRow := dataType{1, *normalString, *nullString, *absentString}

	mock.ExpectExec(regexp.QuoteMeta("INSERT INTO `myTable` (ID, sField, sNullField) VALUES (?, ?, NULL)")).
		WithArgs(1, "some value").
		WillReturnResult(sqlmock.NewResult(1234, 1))

	assert.NoError(t, db.insert("myTable", &dataRow))
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_insert_ignoresFieldsWithoutSQLColumnTag(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	type dataType struct {
		ID    int64
		Field string `sql:"anything:value"`
	}

	dataRow := dataType{1, "my string"}

	mock.ExpectExec(regexp.QuoteMeta("INSERT INTO `myTable` () VALUES ()")).
		WillReturnResult(sqlmock.NewResult(1234, 1))

	assert.NoError(t, db.insert("myTable", &dataRow))
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_insert_WithNonStructValue(t *testing.T) {
	db, _ := NewDBMock()
	defer func() { _ = db.Close() }()

	dataRow := "some value"

	assert.EqualError(t, db.insert("myTable", dataRow), "insert only accepts structs; got reflect.Value")
}

func TestDB_ScanIntoSliceOfMaps(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable`")).
		WillReturnRows(
			mock.NewRows([]string{"ID", "Field"}).
				AddRow(1, "value").AddRow(2, "another value").AddRow(3, nil))

	db = db.Table("myTable")

	var result []map[string]interface{}
	dbScan := db.ScanIntoSliceOfMaps(&result)
	assert.Equal(t, dbScan, db)
	assert.NoError(t, dbScan.Error())

	assert.Equal(t, []map[string]interface{}{
		{"ID": int64(1), "Field": "value"},
		{"ID": int64(2), "Field": "another value"},
		{"ID": int64(3), "Field": nil},
	}, result)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_ScanIntoSliceOfMaps_RowsError(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	expectedError := errors.New("some error")
	mock.ExpectQuery(regexp.QuoteMeta("SELECT * FROM `myTable`")).
		WillReturnError(expectedError)
	db = db.Table("myTable")

	var result []map[string]interface{}
	dbScan := db.ScanIntoSliceOfMaps(&result)
	assert.Equal(t, dbScan, db)
	assert.Equal(t, expectedError, dbScan.Error())

	assert.Nil(t, result)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Updates(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectExec(regexp.QuoteMeta("UPDATE `myTable` SET `id` = ?, `name` = ?")).
		WithArgs(1, "some name").
		WillReturnResult(sqlmock.NewResult(0, 1))

	db = db.Table("myTable")
	updateDB := db.Updates(map[string]interface{}{"id": 1, "name": "some name"})
	assert.NotEqual(t, updateDB, db)
	assert.NoError(t, updateDB.Error())

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_UpdateColumn(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectExec(regexp.QuoteMeta("UPDATE `myTable` SET `name` = ?")).
		WithArgs("some name").
		WillReturnResult(sqlmock.NewResult(0, 1))

	db = db.Table("myTable")
	updateDB := db.UpdateColumn("name", "some name")
	assert.NotEqual(t, updateDB, db)
	assert.NoError(t, updateDB.Error())

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestDB_Set(t *testing.T) {
	db, mock := NewDBMock()
	defer func() { _ = db.Close() }()

	mock.ExpectQuery("SELECT \\* FROM `myTable` FOR UPDATE").
		WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	db = db.Table("myTable")
	setDB := db.Set("gorm:query_option", "FOR UPDATE")
	assert.NotEqual(t, setDB, db)
	assert.NoError(t, setDB.Error())

	var result []interface{}
	assert.NoError(t, setDB.Scan(&result).Error())
	assert.NoError(t, mock.ExpectationsWereMet())
}