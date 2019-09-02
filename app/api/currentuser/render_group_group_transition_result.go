package currentuser

import (
	"errors"
	"net/http"

	"github.com/go-chi/render"

	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// RenderGroupGroupTransitionResult renders database.GroupGroupTransitionResult as a response or returns an APIError
func RenderGroupGroupTransitionResult(w http.ResponseWriter, r *http.Request, result database.GroupGroupTransitionResult,
	action userGroupRelationAction) service.APIError {
	isCreateAction := action == createGroupRequestAction || action == joinGroupByCodeAction
	switch result {
	case database.Cycle:
		return service.ErrUnprocessableEntity(errors.New("cycles in the group relations graph are not allowed"))
	case database.Invalid:
		if isCreateAction {
			return service.ErrUnprocessableEntity(errors.New("a conflicting relation exists"))
		}
		return service.ErrNotFound(errors.New("no such relation"))
	case database.Unchanged:
		statusCode := 200
		if isCreateAction {
			statusCode = 201
		}
		service.MustNotBeError(render.Render(w, r, service.UnchangedSuccess(statusCode)))
	case database.Success:
		renderGroupGroupTransitionSuccess(isCreateAction, action == leaveGroupAction, w, r)
	}
	return service.NoError
}

func renderGroupGroupTransitionSuccess(isCreateAction, isDeleteAction bool, w http.ResponseWriter, r *http.Request) {
	var successRenderer render.Renderer
	switch {
	case isCreateAction:
		successRenderer = service.CreationSuccess(map[string]bool{"changed": true})
	case isDeleteAction:
		successRenderer = service.DeletionSuccess(map[string]bool{"changed": true})
	default:
		successRenderer = service.UpdateSuccess(map[string]bool{"changed": true})
	}
	service.MustNotBeError(render.Render(w, r, successRenderer))
}