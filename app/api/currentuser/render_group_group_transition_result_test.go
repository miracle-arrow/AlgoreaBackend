package currentuser

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

func TestRenderGroupGroupTransitionResult(t *testing.T) {
	tests := []struct {
		name             string
		result           database.GroupGroupTransitionResult
		actions          []userGroupRelationAction
		wantStatusCode   int
		wantResponseBody string
	}{
		{
			name:           "cycle",
			result:         database.Cycle,
			wantStatusCode: http.StatusUnprocessableEntity,
			wantResponseBody: `{"success":false,"message":"Unprocessable Entity",` +
				`"error_text":"Cycles in the group relations graph are not allowed"}`,
		},
		{
			name:             "invalid (not found)",
			result:           database.Invalid,
			actions:          []userGroupRelationAction{acceptInvitationAction, rejectInvitationAction, leaveGroupAction},
			wantStatusCode:   http.StatusNotFound,
			wantResponseBody: `{"success":false,"message":"Not Found","error_text":"No such relation"}`,
		},
		{
			name:           "invalid (unprocessable entity)",
			result:         database.Invalid,
			actions:        []userGroupRelationAction{createGroupRequestAction, joinGroupByCodeAction},
			wantStatusCode: http.StatusUnprocessableEntity,
			wantResponseBody: `{"success":false,"message":"Unprocessable Entity",` +
				`"error_text":"A conflicting relation exists"}`,
		},
		{
			name:             "unchanged (created)",
			result:           database.Unchanged,
			actions:          []userGroupRelationAction{createGroupRequestAction, joinGroupByCodeAction},
			wantStatusCode:   http.StatusCreated,
			wantResponseBody: `{"success":true,"message":"unchanged","data":{"changed":false}}`,
		},
		{
			name:             "unchanged (ok)",
			result:           database.Unchanged,
			actions:          []userGroupRelationAction{acceptInvitationAction, rejectInvitationAction, leaveGroupAction},
			wantStatusCode:   http.StatusOK,
			wantResponseBody: `{"success":true,"message":"unchanged","data":{"changed":false}}`,
		},
		{
			name:             "success (updated)",
			result:           database.Success,
			actions:          []userGroupRelationAction{acceptInvitationAction, rejectInvitationAction},
			wantStatusCode:   http.StatusOK,
			wantResponseBody: `{"success":true,"message":"updated","data":{"changed":true}}`,
		},
		{
			name:             "success (created)",
			result:           database.Success,
			actions:          []userGroupRelationAction{createGroupRequestAction, joinGroupByCodeAction},
			wantStatusCode:   http.StatusCreated,
			wantResponseBody: `{"success":true,"message":"created","data":{"changed":true}}`,
		},
		{
			name:             "success (deleted)",
			actions:          []userGroupRelationAction{leaveGroupAction},
			result:           database.Success,
			wantStatusCode:   http.StatusOK,
			wantResponseBody: `{"success":true,"message":"deleted","data":{"changed":true}}`,
		},
	}
	for _, tt := range tests {
		tt := tt
		if len(tt.actions) == 0 {
			tt.actions = []userGroupRelationAction{
				acceptInvitationAction, joinGroupByCodeAction, rejectInvitationAction,
				createGroupRequestAction, leaveGroupAction,
			}
		}
		for _, action := range tt.actions {
			action := action
			t.Run(tt.name+": "+string(action), func(t *testing.T) {
				var fn service.AppHandler = func(respW http.ResponseWriter, req *http.Request) service.APIError {
					return RenderGroupGroupTransitionResult(respW, req, tt.result, action)
				}
				handler := http.HandlerFunc(fn.ServeHTTP)
				req, _ := http.NewRequest("GET", "/dummy", nil)
				recorder := httptest.NewRecorder()
				handler.ServeHTTP(recorder, req)

				assert.Equal(t, tt.wantStatusCode, recorder.Code)
				assert.Equal(t, tt.wantResponseBody, strings.TrimSpace(recorder.Body.String()))
			})
		}
	}
}