package servicetest

import (
	"net/http"
	"net/http/httptest"
	"strings"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"

	"github.com/France-ioi/AlgoreaBackend/app/auth"
	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/logging"
	"github.com/France-ioi/AlgoreaBackend/app/loggingtest"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// GetResponseForRouteWithMockedDBAndUser executes a route for unit tests
// auth.UserIDFromContext is stubbed to return the given userID.
// The test should provide functions that prepare the router and the sql mock
func GetResponseForRouteWithMockedDBAndUser(
	method string, path string, requestBody string, userID int64,
	setMockExpectationsFunc func(sqlmock.Sqlmock),
	setRouterFunc func(router *chi.Mux, baseService *service.Base)) (*http.Response, sqlmock.Sqlmock, string, error) {

	logger, hook := loggingtest.NewNullLogger()

	db, mock := database.NewDBMock()
	defer func() { _ = db.Close() }() // nolint: gosec

	setMockExpectationsFunc(mock)

	base := service.Base{Store: database.NewDataStore(db), Config: nil}
	router := chi.NewRouter()
	router.Use(auth.MockUserIDMiddleware(userID))
	router.Use(middleware.RequestLogger(&logging.StructuredLogger{Logger: logger}))
	setRouterFunc(router, &base)

	ts := httptest.NewServer(router)
	defer ts.Close()

	request, err := http.NewRequest(method, ts.URL+path, strings.NewReader(requestBody))
	var response *http.Response
	if err == nil {
		response, err = http.DefaultClient.Do(request)
	}

	return response, mock, hook.GetAllLogs(), err
}

// WithLoggingMiddleware wraps the given handler in NullLogger with hook
func WithLoggingMiddleware(appHandler service.AppHandler) (http.Handler, *loggingtest.Hook) {
	logger, hook := loggingtest.NewNullLogger()
	middleware := middleware.RequestLogger(&logging.StructuredLogger{Logger: logger})
	return middleware(appHandler), hook
}