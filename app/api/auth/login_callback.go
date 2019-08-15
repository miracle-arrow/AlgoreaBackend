package auth

import (
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/go-chi/render"
	"github.com/jinzhu/gorm"

	"github.com/France-ioi/AlgoreaBackend/app/auth"
	"github.com/France-ioi/AlgoreaBackend/app/database"
	"github.com/France-ioi/AlgoreaBackend/app/domain"
	"github.com/France-ioi/AlgoreaBackend/app/loginmodule"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// swagger:operation GET /auth/login-callback users auth userLoginCallback
// ---
// summary: Callback to which the user is redirected after authentication with the login module
// description: Creates or updates the authenticated user in the DB using the data returned by the login module,
//              saves the access & refresh tokens in DB as well.
//
//   * No “Authorization” header should be present
//
//   * `login_csrf` cookie set by `/auth/login` should be present
// security: []
// parameters:
// - name: code
//   in: query
//   description: OAuth2 code
//   type: string
//   required: true
// - name: state
//   in: query
//   description: OAuth2 state
//   type: string
//   required: true
// responses:
//   "201":
//     description: "Created. Success response with the new access token"
//     in: body
//     schema:
//       "$ref": "#/definitions/userCreateTmpResponse"
//   "400":
//     "$ref": "#/responses/badRequestResponse"
//   "500":
//     "$ref": "#/responses/internalErrorResponse"
func (srv *Service) loginCallback(w http.ResponseWriter, r *http.Request) service.APIError {
	if len(r.Header["Authorization"]) != 0 {
		return service.ErrInvalidRequest(errors.New("'Authorization' header should not be present"))
	}

	code, err := service.ResolveURLQueryGetStringField(r, "code")
	if err != nil {
		return service.ErrInvalidRequest(err)
	}

	state, err := service.ResolveURLQueryGetStringField(r, "state")
	if err != nil {
		return service.ErrInvalidRequest(err)
	}

	loginState, err := auth.LoadLoginState(srv.Store.LoginStates(), r, state)
	service.MustNotBeError(err)
	if !loginState.IsOK() {
		return service.ErrInvalidRequest(errors.New("wrong state"))
	}

	oauthConfig := getOAuthConfig(&srv.Config.Auth)
	token, err := oauthConfig.Exchange(r.Context(), code)
	service.MustNotBeError(err)

	userProfile, err := loginmodule.NewClient(srv.Config.Auth.LoginModuleURL).GetUserProfile(r.Context(), token.AccessToken)
	service.MustNotBeError(err)
	userProfile["sLastIP"] = strings.SplitN(r.RemoteAddr, ":", 2)[0]

	domainConfig := domain.ConfigFromContext(r.Context())

	service.MustNotBeError(srv.Store.InTransaction(func(store *database.DataStore) error {
		userID := createOrUpdateUser(store.Users(), userProfile, domainConfig)
		service.MustNotBeError(store.Sessions().InsertNewOAuth(userID, token))

		service.MustNotBeError(store.Exec(
			"INSERT INTO refresh_tokens (idUser, sRefreshToken) VALUES (?, ?) ON DUPLICATE KEY UPDATE sRefreshToken = ?",
			userID, token.RefreshToken, token.RefreshToken).Error())

		expiredCookie, err := loginState.Delete(store.LoginStates(), &srv.Config.Server)
		service.MustNotBeError(err)
		if strings.HasPrefix(srv.Config.Auth.CallbackURL, "https") {
			expiredCookie.Secure = true
		}
		http.SetCookie(w, expiredCookie)

		return nil
	}))

	service.MustNotBeError(render.Render(w, r, service.CreationSuccess(map[string]interface{}{
		"access_token": token.AccessToken,
		"expires_in":   time.Until(token.Expiry).Round(time.Second) / time.Second,
	})))
	return service.NoError
}

func createOrUpdateUser(s *database.UserStore, userData map[string]interface{}, domainConfig *domain.Configuration) int64 {
	var userInfo struct {
		ID           int64 `gorm:"column:ID"`
		SelfGroupID  int64 `gorm:"column:idGroupSelf"`
		OwnedGroupID int64 `gorm:"column:idGroupOwned"`
	}
	err := s.WithWriteLock().
		Where("loginID = ?", userData["loginID"]).Select("ID, idGroupSelf, idGroupOwned").
		Take(&userInfo).Error()

	userData["sLastLoginDate"] = database.Now()
	userData["sLastActivityDate"] = database.Now()

	if gorm.IsRecordNotFoundError(err) {
		ownedGroupID, selfGroupID := createGroupsFromLogin(s.Groups(), userData["sLogin"].(string), domainConfig)
		userData["tempUser"] = 0
		userData["sRegistrationDate"] = database.Now()
		userData["idGroupSelf"] = selfGroupID
		userData["idGroupOwned"] = ownedGroupID

		var userID int64
		service.MustNotBeError(s.RetryOnDuplicatePrimaryKeyError(func(retryStore *database.DataStore) error {
			userID = s.NewID()
			userData["ID"] = userID
			return s.Users().InsertMap(userData)
		}))
		return userID
	}

	found, err := s.GroupGroups().Where("idGroupParent = ?", domainConfig.RootSelfGroupID).
		Where("idGroupChild = ?", userInfo.SelfGroupID).HasRows()
	service.MustNotBeError(err)
	groupsToCreate := make([]database.ParentChild, 0, 2)
	if !found {
		groupsToCreate = append(groupsToCreate,
			database.ParentChild{ParentID: domainConfig.RootSelfGroupID, ChildID: userInfo.SelfGroupID})
	}

	found, err = s.GroupGroups().Where("idGroupParent = ?", domainConfig.RootAdminGroupID).
		Where("idGroupChild = ?", userInfo.OwnedGroupID).HasRows()
	service.MustNotBeError(err)
	if !found {
		groupsToCreate = append(groupsToCreate,
			database.ParentChild{ParentID: domainConfig.RootAdminGroupID, ChildID: userInfo.OwnedGroupID})
	}
	service.MustNotBeError(s.GroupGroups().CreateRelationsWithoutChecking(groupsToCreate))

	service.MustNotBeError(err)
	service.MustNotBeError(s.ByID(userInfo.ID).UpdateColumn(userData).Error())
	return userInfo.ID
}

func createGroupsFromLogin(store *database.GroupStore, login string, domainConfig *domain.Configuration) (ownedGroupID, selfGroupID int64) {
	service.MustNotBeError(store.RetryOnDuplicatePrimaryKeyError(func(retryIDStore *database.DataStore) error {
		selfGroupID = retryIDStore.NewID()
		return retryIDStore.Groups().InsertMap(map[string]interface{}{
			"ID":           selfGroupID,
			"sName":        login,
			"sType":        "UserSelf",
			"sDescription": login,
			"sDateCreated": database.Now(),
			"bOpened":      false,
			"bSendEmails":  false,
		})
	}))
	service.MustNotBeError(store.RetryOnDuplicatePrimaryKeyError(func(retryIDStore *database.DataStore) error {
		ownedGroupID = retryIDStore.NewID()
		adminGroupName := login + "-admin"
		return retryIDStore.Groups().InsertMap(map[string]interface{}{
			"ID":           ownedGroupID,
			"sName":        adminGroupName,
			"sType":        "UserAdmin",
			"sDescription": adminGroupName,
			"sDateCreated": database.Now(),
			"bOpened":      false,
			"bSendEmails":  false,
		})
	}))

	service.MustNotBeError(store.GroupGroups().CreateRelationsWithoutChecking([]database.ParentChild{
		{ParentID: domainConfig.RootSelfGroupID, ChildID: selfGroupID},
		{ParentID: domainConfig.RootAdminGroupID, ChildID: ownedGroupID},
	}))

	return ownedGroupID, selfGroupID
}