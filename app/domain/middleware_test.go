package domain

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/France-ioi/AlgoreaBackend/app/config"
)

func TestMiddleware(t *testing.T) {
	tests := []struct {
		name               string
		domains            []config.Domain
		expectedConfig     *Configuration
		expectedStatusCode int
		expectedBody       string
		shouldEnterService bool
	}{
		{
			name: "ok",
			domains: []config.Domain{
				{
					Domains:   []string{"france-ioi.org", "www.france-ioi.org"},
					RootGroup: 5, RootSelfGroup: 6, RootAdminGroup: 7, RootTempGroup: 7,
				},
				{
					Domains:   []string{"192.168.0.1", "127.0.0.1"},
					RootGroup: 1, RootSelfGroup: 2, RootAdminGroup: 3, RootTempGroup: 4,
				},
			},
			expectedConfig:     &Configuration{RootGroupID: 1, RootSelfGroupID: 2, RootAdminGroupID: 3, RootTempGroupID: 4},
			expectedStatusCode: http.StatusOK,
			shouldEnterService: true,
		},
		{
			name: "wrong domain",
			domains: []config.Domain{
				{
					Domains:   []string{"france-ioi.org", "www.france-ioi.org"},
					RootGroup: 4, RootSelfGroup: 5, RootAdminGroup: 6, RootTempGroup: 7,
				},
				{
					Domains:   []string{"192.168.0.1"},
					RootGroup: 1, RootSelfGroup: 2, RootAdminGroup: 3, RootTempGroup: 4,
				},
			},
			expectedStatusCode: http.StatusNotImplemented,
			expectedBody:       "{\"success\":false,\"message\":\"Not implemented\",\"error_text\":\"Wrong domain \\\"127.0.0.1\\\"\"}",
			shouldEnterService: false,
		},
	}
	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			assertMiddleware(t, tt.domains, tt.shouldEnterService, tt.expectedStatusCode, tt.expectedBody, tt.expectedConfig)
		})
	}
}

func assertMiddleware(t *testing.T, domains []config.Domain, shouldEnterService bool,
	expectedStatusCode int, expectedBody string, expectedConfig *Configuration) {
	// dummy server using the middleware
	middleware := Middleware(domains)
	enteredService := false // used to log if the service has been reached
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		enteredService = true // has passed into the service
		configuration := r.Context().Value(ctxDomainConfig).(*Configuration)
		assert.Equal(t, expectedConfig, configuration)
		w.WriteHeader(http.StatusOK)
	})
	mainSrv := httptest.NewServer(middleware(handler))
	defer mainSrv.Close()

	// calling web server
	mainRequest, _ := http.NewRequest("GET", mainSrv.URL, nil)
	client := &http.Client{}
	response, err := client.Do(mainRequest)
	var body string
	if err == nil {
		bodyData, _ := ioutil.ReadAll(response.Body)
		_ = response.Body.Close()
		body = string(bodyData)
	}
	assert.NoError(t, err)
	assert.Equal(t, expectedBody, body)
	assert.Equal(t, expectedStatusCode, response.StatusCode)
	assert.Equal(t, shouldEnterService, enteredService)
}