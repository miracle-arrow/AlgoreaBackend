package groups

import (
	"net/http"

	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// swagger:operation POST /groups/{parent_group_id}/invitations/withdraw groups groupInvitationsWithdraw
// ---
// summary: Withdraw invitations to join a group
// description:
//   Lets a manager withdraw invitations to join a group.
//   On success the service removes rows with `type` = 'invitation' from `group_pending_requests` and
//   creates new rows with `action` = 'invitation_withdrawn' and `at` = current UTC time in `group_membership_changes`
//   for each of `group_ids`.
//
//
//   The authenticated user should be a manager of the `parent_group_id` with `can_manage` >= 'memberships',
//   otherwise the 'forbidden' error is returned.
//
//
//   There should be a row with `type` = 'invitation' and `group_id` = `{parent_group_id}`
//   in `group_pending_requests` for each of the input `group_ids`, otherwise the `group_id` gets skipped with
//   `invalid` as the result.
//
//
//   The response status code on success (200) doesn't depend on per-group results.
// parameters:
// - name: parent_group_id
//   in: path
//   type: integer
//   required: true
// - name: group_ids
//   in: query
//   type: array
//   items:
//     type: integer
//   required: true
// responses:
//   "200":
//     "$ref": "#/responses/updatedGroupRelationsResponse"
//   "400":
//     "$ref": "#/responses/badRequestResponse"
//   "401":
//     "$ref": "#/responses/unauthorizedResponse"
//   "403":
//     "$ref": "#/responses/forbiddenResponse"
//   "500":
//     "$ref": "#/responses/internalErrorResponse"
func (srv *Service) withdrawInvitations(w http.ResponseWriter, r *http.Request) service.APIError {
	return srv.performBulkMembershipAction(w, r, withdrawInvitationsAction)
}
