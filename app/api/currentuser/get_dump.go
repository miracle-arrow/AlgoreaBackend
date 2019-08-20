package currentuser

import (
	"net/http"

	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// swagger:operation GET /current-user/dump users currentUserDataExport
// ---
// summary: Export the short version of the current user's data
// description: >
//   Returns a downloadable JSON file with all the short version of the current user's data.
//   The content returned is just the dump of raw entries of tables related to the user
//
//     * `current_user` (from `users`): all attributes except `iVersion`
//     * `owned_groups`: `ID` and `sName` for every descendant of user’s `idGroupOwned`;
//     * `joined_groups`: `ID` and `sName` for every ancestor of user’s `idGroupSelf`;
//     * `groups_groups`: where the user’s `idGroupSelf` is the `idGroupChild`, all attributes except `iVersion` + `groups.sName`.
//
//   In case of unexpected error (e.g. a DB error), the response will be a malformed JSON like
//   ```{"current_user":{"success":false,"message":"Internal Server Error","error_text":"Some error"}```
// produces:
//   - application/json
// responses:
//   "200":
//     description: The returned data dump file
//     schema:
//       type: file
//   "401":
//     "$ref": "#/responses/unauthorizedResponse"
//   "500":
//     "$ref": "#/responses/internalErrorResponse"
func (srv *Service) getDump(w http.ResponseWriter, r *http.Request) service.APIError {
	return srv.getDumpCommon(r, w, false)
}