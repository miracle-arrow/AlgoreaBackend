package groups

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/go-chi/render"

	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// swagger:model groupUserRequestsViewResponseRow
type groupUserRequestsViewResponseRow struct {
	// Nullable
	// required: true
	At *database.Time `json:"at"`

	// required: true
	Group struct {
		// required: true
		ID int64 `json:"id,string"`
		// required: true
		Name string `json:"name"`
	} `json:"group" gorm:"embedded;embedded_prefix:group__"`

	// required: true
	User struct {
		// `users.group_id`
		// required: true
		GroupID *int64 `json:"group_id,string"`
		// required: true
		Login string `json:"login"`
		// Nullable
		// required: true
		FirstName *string `json:"first_name"`
		// Nullable
		// required: true
		LastName *string `json:"last_name"`
		// Nullable
		// required: true
		Grade *int32 `json:"grade"`
	} `json:"user" gorm:"embedded;embedded_prefix:user__"`
}

// swagger:operation GET /groups/user-requests group-memberships groupUserRequestsView
// ---
// summary: List pending requests for managed groups
// description: >
//
//   Returns a list of group pending requests created by users with types listed in `{types}`
//   (rows from the `group_pending_requests` table) with basic info on joining/leaving users
//   for the group (if `{group_id}` is given) and
//   its descendants (if `{group_id}` is given and `{include_descendant_groups}` is 1)
//   or for all groups the current user can manage
//   (`can_manage` >= 'memberships') (if `{group_id}` is not given).
//
//
//   If `{group_id}` is given, the authenticated user should be a manager of `group_id` with `can_manage` >= 'memberships',
//   otherwise the 'forbidden' error is returned. If the group is a user, the 'forbidden' error is returned as well.
// parameters:
// - name: group_id
//   in: query
//   type: integer
// - name: include_descendant_groups
//   in: query
//   type: integer
//   enum: [0,1]
//   default: 0
// - name: types
//   in: query
//   default: [join_request]
//   type: array
//   items:
//     type: string
//     enum: [join_request,leave_request]
// - name: sort
//   in: query
//   default: [group.id,-at,user.group_id]
//   type: array
//   items:
//     type: string
//     enum: [at,-at,user.login,-user.login,group.name,-group.name,user.group_id,-user.group_id,group.id,-group.id]
// - name: from.at
//   description: Start the page from the request next to the request with
//                `group_pending_requests.at` = `from.at`
//                (depending on the `sort` parameter, some other `from.*` parameters may be required)
//   in: query
//   type: string
// - name: from.user.login
//   description: Start the page from the request next to the request
//                whose user's login is `from.user.login`
//                (depending on the `sort` parameter, some other `from.*` parameters may be required)
//   in: query
//   type: string
// - name: from.group.name
//   description: Start the page from the request next to request with name = `from.user.login`
//                (depending on the `sort` parameter, some other `from.*` parameters may be required)
//   in: query
//   type: string
// - name: from.group.id
//   description: Start the page from the request next to the request with
//                `group_pending_requests.group_id`=`from.group.id`
//                (depending on the `sort` parameter, some other `from.*` parameters may be required)
//   in: query
//   type: integer
// - name: from.user.group_id
//   description: Start the page from the request next to the request with
//                `group_pending_requests.member_id`=`from.user.group_id`
//                (depending on the `sort` parameter, some other `from.*` parameters may be required)
//   in: query
//   type: integer
// - name: limit
//   description: Display the first N requests
//   in: query
//   type: integer
//   maximum: 1000
//   default: 500
// responses:
//   "200":
//     description: OK. The array of pending group requests
//     schema:
//       type: array
//       items:
//         "$ref": "#/definitions/groupUserRequestsViewResponseRow"
//   "400":
//     "$ref": "#/responses/badRequestResponse"
//   "401":
//     "$ref": "#/responses/unauthorizedResponse"
//   "403":
//     "$ref": "#/responses/forbiddenResponse"
//   "500":
//     "$ref": "#/responses/internalErrorResponse"
func (srv *Service) getUserRequests(w http.ResponseWriter, r *http.Request) service.APIError {
	groupID, groupIDSet, includeDescendantGroups, types, apiError := srv.resolveParametersForGetUserRequests(r)
	if apiError != service.NoError {
		return apiError
	}

	query := srv.Store.GroupPendingRequests().
		Select(`
			group_pending_requests.at,
			group.id AS group__id,
			group.name AS group__name,
			user.group_id AS user__group_id,
			user.login AS user__login,
			user.first_name AS user__first_name,
			user.last_name AS user__last_name,
			user.grade AS user__grade`).
		Joins("JOIN `groups` AS `group` ON group.id = group_pending_requests.group_id").
		Joins(`LEFT JOIN users AS user ON user.group_id = member_id`).
		Where("group_pending_requests.type IN (?)", types)
	tieBreakerFieldNames := []string{"group.id", "user.group_id"}
	if groupIDSet {
		if includeDescendantGroups {
			query = query.Joins("JOIN groups_ancestors_active ON groups_ancestors_active.child_group_id = group_pending_requests.group_id").
				Where("groups_ancestors_active.ancestor_group_id = ?", groupID)
		} else {
			query = query.Where("group_pending_requests.group_id = ?", groupID)
			tieBreakerFieldNames = []string{"user.group_id"}
		}
	} else {
		query = query.Where("group_pending_requests.group_id IN ?",
			srv.Store.ActiveGroupAncestors().ManagedByUser(srv.GetUser(r)).Where("can_manage != 'none'").
				Select("groups_ancestors_active.child_group_id").SubQuery())
	}

	query = service.NewQueryLimiter().Apply(r, query)
	query, apiError = service.ApplySortingAndPaging(r, query,
		map[string]*service.FieldSortingParams{
			"user.login":    {ColumnName: "user.login", FieldType: "string"},
			"user.group_id": {ColumnName: "group_pending_requests.member_id", FieldType: "int64"},
			"at":            {ColumnName: "group_pending_requests.at", FieldType: "time"},
			"group.name":    {ColumnName: "group.name", FieldType: "string"},
			"group.id":      {ColumnName: "group_pending_requests.group_id", FieldType: "int64"}},
		"group.id,-at,user.group_id",
		tieBreakerFieldNames, false)

	if apiError != service.NoError {
		return apiError
	}

	var result []groupUserRequestsViewResponseRow
	service.MustNotBeError(query.Scan(&result).Error())

	render.Respond(w, r, result)
	return service.NoError
}

func (srv *Service) resolveParametersForGetUserRequests(r *http.Request) (
	groupID int64, groupIDSet, includeDescendantGroups bool, types []string, apiError service.APIError) {
	user := srv.GetUser(r)

	var err error

	urlQuery := r.URL.Query()
	if len(urlQuery["group_id"]) > 0 {
		groupIDSet = true
		groupID, err = service.ResolveURLQueryGetInt64Field(r, "group_id")
		if err != nil {
			return 0, false, false, nil, service.ErrInvalidRequest(err)
		}

		if apiError = checkThatUserCanManageTheGroupMemberships(srv.Store, user, groupID); apiError != service.NoError {
			return 0, false, false, nil, apiError
		}

		if len(urlQuery["include_descendant_groups"]) > 0 {
			includeDescendantGroups, err = service.ResolveURLQueryGetBoolField(r, "include_descendant_groups")
			if err != nil {
				return 0, false, false, nil, service.ErrInvalidRequest(err)
			}
		}
	} else if len(urlQuery["include_descendant_groups"]) > 0 {
		return 0, false, false, nil,
			service.ErrInvalidRequest(errors.New("'include_descendant_groups' should not be given when 'group_id' is not given"))
	}

	types, apiError = resolveTypesParameterForGetUserRequests(r)
	return groupID, groupIDSet, includeDescendantGroups, types, apiError
}

func resolveTypesParameterForGetUserRequests(r *http.Request) ([]string, service.APIError) {
	types := []string{"join_request"}
	urlQuery := r.URL.Query()
	if len(urlQuery["types"]) > 0 {
		types, _ = service.ResolveURLQueryGetStringSliceField(r, "types")
		for _, typ := range types {
			if !map[string]bool{"join_request": true, "leave_request": true}[typ] {
				return nil, service.ErrInvalidRequest(fmt.Errorf("wrong value in 'types': %q", typ))
			}
		}
	}
	return types, service.NoError
}