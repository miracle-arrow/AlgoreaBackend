package logging_test

import (
	"errors"
	"os"
	"testing"
	"time"

	"github.com/sirupsen/logrus/hooks/test"
	assertlib "github.com/stretchr/testify/assert"

	"github.com/France-ioi/AlgoreaBackend/app/config"
	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/logging"
)

func TestStructuredDBLogger_Print_SQL(t *testing.T) {
	assert := assertlib.New(t)
	var hook *test.Hook
	config.ClearCachedConfig()
	defer config.ClearCachedConfig()
	_ = os.Setenv("ALGOREA_LOGGING.FORMAT", "json")
	_ = os.Setenv("ALGOREA_LOGGING.LOGSQLQUERIES", "1")
	logging.Logger, hook = test.NewNullLogger()
	db, mock := database.NewDBMock()

	mock.ExpectQuery("SELECT 1").WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	var result []interface{}
	timeParam := time.Date(2009, time.November, 10, 23, 0, 0, 0, time.UTC)
	db.Raw("SELECT $1, $2, $3, $4, $5", 1, timeParam, "foo", []byte("bar"), nil).Scan(&result)
	assert.Equal("SELECT '1', '2009-11-10 23:00:00', 'foo', 'bar', NULL", hook.LastEntry().Message)
	data := hook.LastEntry().Data
	assert.Equal("db", data["type"])
	assert.True(data["duration"].(float64) < 0.01, "unexpected duration: %v", data["duration"])
	assert.NotNil(data["ts"])
	assert.Equal(int64(0), data["rows"].(int64))
}

func TestStructuredDBLogger_Print_SQLWithInterrogationMark(t *testing.T) {
	assert := assertlib.New(t)
	var hook *test.Hook
	config.ClearCachedConfig()
	defer config.ClearCachedConfig()
	_ = os.Setenv("ALGOREA_LOGGING.FORMAT", "json")
	_ = os.Setenv("ALGOREA_LOGGING.LOGSQLQUERIES", "1")
	logging.Logger, hook = test.NewNullLogger()
	db, mock := database.NewDBMock()

	mock.ExpectQuery("SELECT 1").WillReturnRows(mock.NewRows([]string{"1"}).AddRow(1))

	var result []interface{}
	db.Raw("SELECT ?", 1).Scan(&result)
	assert.Equal("SELECT '1'", hook.LastEntry().Message)
}

func TestStructuredDBLogger_Print_SQLError(t *testing.T) {
	assert := assertlib.New(t)
	var hook *test.Hook
	config.ClearCachedConfig()
	defer config.ClearCachedConfig()
	_ = os.Setenv("ALGOREA_LOGGING.FORMAT", "json")
	_ = os.Setenv("ALGOREA_LOGGING.LOGSQLQUERIES", "1")
	logging.Logger, hook = test.NewNullLogger()
	db, mock := database.NewDBMock()

	mock.ExpectQuery("SELECT 2").WillReturnError(errors.New("a query error"))

	var result []interface{}
	db.Raw("SELECT 2").Scan(&result)

	assert.Equal("a query error", hook.Entries[0].Message)
	data := hook.Entries[0].Data
	assert.Equal("db", data["type"])

	assert.Equal("SELECT 2", hook.Entries[1].Message)
	data = hook.Entries[1].Data
	assert.Equal("db", data["type"])
	assert.True(data["duration"].(float64) < 0.01, "unexpected duration: %v", data["duration"])
	assert.NotNil(data["ts"])
	assert.Equal(int64(0), data["rows"].(int64))
}
