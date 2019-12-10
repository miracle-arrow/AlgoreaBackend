package groups

import (
	"net/http"

	"github.com/go-chi/chi"
	"github.com/go-chi/render"

	"github.com/France-ioi/AlgoreaBackend/app/auth"
	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// Service is the mount point for services related to `groups`
type Service struct {
	service.Base
}

// SetRoutes defines the routes for this package in a route group
func (srv *Service) SetRoutes(router chi.Router) {
	router.Use(render.SetContentType(render.ContentTypeJSON))
	router.Use(auth.UserMiddleware(srv.Store.Sessions()))
	router.Get("/groups/{group_id}/recent_activity", service.AppHandler(srv.getRecentActivity).ServeHTTP)
	router.Post("/groups", service.AppHandler(srv.createGroup).ServeHTTP)
	router.Get("/groups/{group_id}", service.AppHandler(srv.getGroup).ServeHTTP)
	router.Put("/groups/{group_id}", service.AppHandler(srv.updateGroup).ServeHTTP)
	router.Put("/groups/{group_id}/items/{item_id}", service.AppHandler(srv.updatePermissions).ServeHTTP)

	router.Post("/groups/{group_id}/code", service.AppHandler(srv.changeCode).ServeHTTP)
	router.Delete("/groups/{group_id}/code", service.AppHandler(srv.discardCode).ServeHTTP)

	router.Get("/groups/{group_id}/children", service.AppHandler(srv.getChildren).ServeHTTP)
	router.Get("/groups/{group_id}/team-descendants", service.AppHandler(srv.getTeamDescendants).ServeHTTP)
	router.Get("/groups/{group_id}/user-descendants", service.AppHandler(srv.getUserDescendants).ServeHTTP)
	router.Get("/groups/{group_id}/members", service.AppHandler(srv.getMembers).ServeHTTP)
	router.Delete("/groups/{group_id}/members", service.AppHandler(srv.removeMembers).ServeHTTP)

	router.Get("/groups/{group_id}/requests", service.AppHandler(srv.getRequests).ServeHTTP)
	router.Get("/groups/{group_id}/group-progress", service.AppHandler(srv.getGroupProgress).ServeHTTP)
	router.Get("/groups/{group_id}/team-progress", service.AppHandler(srv.getTeamProgress).ServeHTTP)
	router.Get("/groups/{group_id}/user-progress", service.AppHandler(srv.getUserProgress).ServeHTTP)
	router.Post("/groups/{parent_group_id}/requests/accept", service.AppHandler(srv.acceptJoinRequests).ServeHTTP)
	router.Post("/groups/{parent_group_id}/requests/reject", service.AppHandler(srv.rejectJoinRequests).ServeHTTP)
	router.Post("/groups/{parent_group_id}/leave-requests/accept", service.AppHandler(srv.acceptLeaveRequests).ServeHTTP)
	router.Post("/groups/{parent_group_id}/leave-requests/reject", service.AppHandler(srv.rejectLeaveRequests).ServeHTTP)

	router.Post("/groups/{parent_group_id}/invitations", service.AppHandler(srv.inviteUsers).ServeHTTP)
	router.Post("/groups/{parent_group_id}/invitations/withdraw", service.AppHandler(srv.withdrawInvitations).ServeHTTP)

	router.Post("/groups/{parent_group_id}/relations/{child_group_id}", service.AppHandler(srv.addChild).ServeHTTP)
	router.Delete("/groups/{parent_group_id}/relations/{child_group_id}", service.AppHandler(srv.removeChild).ServeHTTP)

	router.Get("/current-user/teams/by-item/{item_id}", service.AppHandler(srv.getCurrentUserTeamByItem).ServeHTTP)
}

func checkThatUserCanManageTheGroup(store *database.DataStore, user *database.User, groupID int64) service.APIError {
	found, err := store.GroupAncestors().ManagedByUser(user).
		Where("groups_ancestors.child_group_id = ?", groupID).HasRows()
	service.MustNotBeError(err)
	if !found {
		return service.InsufficientAccessRightsError
	}
	return service.NoError
}

func checkThatUserCanManageTheGroupMemberships(store *database.DataStore, user *database.User, groupID int64) service.APIError {
	found, err := store.GroupAncestors().ManagedByUser(user).
		Where("groups_ancestors.child_group_id = ?", groupID).
		Where("group_managers.can_manage != 'none'").HasRows()
	service.MustNotBeError(err)
	if !found {
		return service.InsufficientAccessRightsError
	}
	return service.NoError
}

type createOrDeleteRelation bool

const (
	createRelation createOrDeleteRelation = true
	deleteRelation createOrDeleteRelation = false
)

func checkThatUserHasRightsForDirectRelation(
	store *database.DataStore, user *database.User,
	parentGroupID, childGroupID int64, createOrDelete createOrDeleteRelation) service.APIError {

	groupStore := store.Groups()

	var groupData []struct {
		ID   int64
		Type string
	}

	query := groupStore.ManagedBy(user).
		WithWriteLock().
		Select("groups.id, type").
		Where("groups.id IN(?, ?)", parentGroupID, childGroupID).
		Where("IF(groups.id = ?, group_managers.can_manage != 'none', 1)", parentGroupID)

	if createOrDelete == createRelation {
		query = query.Where("IF(groups.id = ?, group_managers.can_manage = 'memberships_and_group', 1)", childGroupID)
	}

	err := query.
		Group("groups.id").
		Scan(&groupData).Error()
	service.MustNotBeError(err)

	if len(groupData) < 2 {
		return service.InsufficientAccessRightsError
	}

	for _, groupRow := range groupData {
		if (groupRow.ID == parentGroupID && map[string]bool{"UserSelf": true, "Team": true}[groupRow.Type]) ||
			(groupRow.ID == childGroupID &&
				map[string]bool{"Base": true, "UserSelf": true}[groupRow.Type]) {
			return service.InsufficientAccessRightsError
		}
	}
	return service.NoError
}

type bulkMembershipAction string

const (
	acceptJoinRequestsAction  bulkMembershipAction = "acceptJoinRequests"
	rejectJoinRequestsAction  bulkMembershipAction = "rejectJoinRequests"
	acceptLeaveRequestsAction bulkMembershipAction = "acceptLeaveRequests"
	rejectLeaveRequestsAction bulkMembershipAction = "rejectLeaveRequests"
	withdrawInvitationsAction bulkMembershipAction = "withdrawInvitations"
)

const inAnotherTeam = "in_another_team"
const notFound = "not_found"

func (srv *Service) performBulkMembershipAction(w http.ResponseWriter, r *http.Request,
	action bulkMembershipAction) service.APIError {
	parentGroupID, err := service.ResolveURLQueryPathInt64Field(r, "parent_group_id")
	if err != nil {
		return service.ErrInvalidRequest(err)
	}

	groupIDs, err := service.ResolveURLQueryGetInt64SliceField(r, "group_ids")
	if err != nil {
		return service.ErrInvalidRequest(err)
	}

	user := srv.GetUser(r)
	if apiErr := checkThatUserCanManageTheGroupMemberships(srv.Store, user, parentGroupID); apiErr != service.NoError {
		return apiErr
	}

	var results database.GroupGroupTransitionResults
	var filteredIDs []int64
	if len(groupIDs) > 0 {
		err = srv.Store.InTransaction(func(store *database.DataStore) error {
			if action == acceptJoinRequestsAction {
				groupIDs, filteredIDs = filterOtherTeamsMembersOut(store, parentGroupID, groupIDs)
			}

			results, err = store.GroupGroups().Transition(
				map[bulkMembershipAction]database.GroupGroupTransitionAction{
					acceptJoinRequestsAction:  database.AdminAcceptsJoinRequest,
					rejectJoinRequestsAction:  database.AdminRefusesJoinRequest,
					withdrawInvitationsAction: database.AdminWithdrawsInvitation,
					acceptLeaveRequestsAction: database.AdminAcceptsLeaveRequest,
					rejectLeaveRequestsAction: database.AdminRefusesLeaveRequest,
				}[action], parentGroupID, groupIDs, user.GroupID)
			return err
		})
	}

	service.MustNotBeError(err)

	for _, id := range filteredIDs {
		results[id] = inAnotherTeam
	}
	renderGroupGroupTransitionResults(w, r, results)
	return service.NoError
}

type descendantParent struct {
	// required:true
	ID int64 `json:"id,string"`
	// required:true
	Name string `json:"name"`

	LinkedGroupID int64 `json:"-"`
}

func filterOtherTeamsMembersOut(
	store *database.DataStore, parentGroupID int64, groups []int64) (filteredGroupsList, excludedGroups []int64) {
	groupsToInviteMap := make(map[int64]bool, len(groups))
	for _, id := range groups {
		groupsToInviteMap[id] = true
	}

	otherTeamsMembers := getOtherTeamsMembers(store, parentGroupID, groups)
	for _, id := range otherTeamsMembers {
		delete(groupsToInviteMap, id)
	}
	newGroupsToInvite := make([]int64, 0, len(groupsToInviteMap))
	for _, id := range groups {
		if groupsToInviteMap[id] {
			newGroupsToInvite = append(newGroupsToInvite, id)
		}
	}
	return newGroupsToInvite, otherTeamsMembers
}
