package testhelpers

import (
	"database/sql"
	"fmt"
	"io"
	"io/ioutil"
	"math/rand"
	"net/http"
	"net/http/httptest"
	"os"

	"bou.ke/monkey"
	"github.com/CloudyKit/jet"
	"github.com/DATA-DOG/godog/gherkin"
	_ "github.com/go-sql-driver/mysql"      // use to force database/sql to use mysql
	"github.com/sirupsen/logrus/hooks/test" //nolint:depguard
	"github.com/thingful/httpmock"

	"github.com/France-ioi/AlgoreaBackend/app"
	log "github.com/France-ioi/AlgoreaBackend/app/logging"
	"github.com/France-ioi/AlgoreaBackend/app/loggingtest"
)

type dbquery struct {
	sql    string
	values []interface{}
}

// TestContext implements context for tests
type TestContext struct {
	// nolint
	application      *app.Application // do NOT call it directly, use `app()`
	userID           int64            // userID that will be used for the next requests
	featureQueries   []dbquery
	lastResponse     *http.Response
	lastResponseBody string
	logsHook         *loggingtest.Hook
	logsRestoreFunc  func()
	inScenario       bool
	dbTableData      map[string]*gherkin.DataTable
	templateSet      *jet.Set
	requestHeaders   map[string][]string
}

var db *sql.DB

const testAccessToken = "testsessiontestsessiontestsessio"

func (ctx *TestContext) SetupTestContext(data interface{}) { // nolint
	switch scenario := data.(type) {
	case *gherkin.Scenario:
		log.WithField("type", "test").Infof("Starting test scenario: %s", scenario.Name)
	case *gherkin.ScenarioOutline:
		log.WithField("type", "test").Infof("Starting test scenario: %s", scenario.Name)
	}

	var logHook *test.Hook
	logHook, ctx.logsRestoreFunc = log.MockSharedLoggerHook()
	ctx.logsHook = &loggingtest.Hook{Hook: logHook}

	ctx.setupApp()
	ctx.userID = 0 // not set
	ctx.lastResponse = nil
	ctx.lastResponseBody = ""
	ctx.inScenario = true
	ctx.requestHeaders = map[string][]string{}
	ctx.dbTableData = make(map[string]*gherkin.DataTable)
	ctx.templateSet = ctx.constructTemplateSet()

	// reset the seed to get predictable results on PRNG for tests
	rand.Seed(1)

	err := ctx.initDB()
	if err != nil {
		fmt.Println("Unable to empty db")
		panic(err)
	}
}

func (ctx *TestContext) setupApp() {
	var err error
	ctx.tearDownApp()
	ctx.application, err = app.New()
	if err != nil {
		fmt.Println("Unable to load app")
		panic(err)
	}
}

func (ctx *TestContext) tearDownApp() {
	if ctx.application != nil {
		_ = ctx.application.Database.Close() // nolint:gosec
	}
	ctx.application = nil
}

func (ctx *TestContext) ScenarioTeardown(interface{}, error) { // nolint
	RestoreDBTime()
	monkey.UnpatchAll()
	ctx.logsRestoreFunc()

	defer func() {
		if err := httpmock.AllStubsCalled(); err != nil {
			panic(err) // godog doesn't allow to return errors from handlers (see https://github.com/DATA-DOG/godog/issues/88)
		}
		httpmock.DeactivateAndReset()
	}()

	ctx.tearDownApp()
}

func testRequest(ts *httptest.Server, method, path string, headers map[string][]string, body io.Reader) (*http.Response, string, error) {
	req, err := http.NewRequest(method, ts.URL+path, body)
	if err != nil {
		return nil, "", err
	}

	// add headers
	for name, values := range headers {
		for _, value := range values {
			req.Header.Add(name, value)
		}
	}

	client := http.Client{CheckRedirect: func(*http.Request, []*http.Request) error {
		return http.ErrUseLastResponse
	}}
	// execute the query
	resp, err := client.Do(req)
	if err != nil {
		return nil, "", err
	}

	respBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, "", err
	}
	defer func() { /* #nosec */ _ = resp.Body.Close() }()

	return resp, string(respBody), nil
}

func (ctx *TestContext) db() *sql.DB {
	if db == nil {
		conf := ctx.application.Config
		var err error
		db, err = sql.Open("mysql", conf.Database.Connection.FormatDSN())
		if err != nil {
			fmt.Println("Unable to connect to the database: ", err)
			os.Exit(1)
		}
	}
	return db
}

// nolint: gosec
func (ctx *TestContext) emptyDB() error {

	db := ctx.db()

	dbName := ctx.application.Config.Database.Connection.DBName
	rows, err := db.Query(`SELECT CONCAT(table_schema, '.', table_name)
                         FROM   information_schema.tables
                         WHERE  table_type   = 'BASE TABLE'
                           AND  table_schema = '` + dbName + `'
                           AND  table_name  != 'gorp_migrations'`)
	if err != nil {
		return err
	}
	defer func() { _ = rows.Close() }()

	for rows.Next() {
		var tableName string
		if scanErr := rows.Scan(&tableName); scanErr != nil {
			return scanErr
		}
		// DELETE is MUCH faster than TRUNCATE on empty tables
		_, err := db.Exec("DELETE FROM " + tableName)
		if err != nil {
			return err
		}
	}
	return nil
}

func (ctx *TestContext) initDB() error {
	err := ctx.emptyDB()
	if err != nil {
		return err
	}
	db := ctx.db()

	for _, query := range ctx.featureQueries {
		_, err := db.Exec(query.sql, query.values)
		if err != nil {
			return err
		}
	}

	return nil
}
