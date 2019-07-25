package auth

import (
	"net/http"
	"time"

	"github.com/jinzhu/gorm"

	"github.com/France-ioi/AlgoreaBackend/app/config"
	"github.com/France-ioi/AlgoreaBackend/app/database"
)

const loginStateLifetimeInSeconds = int32(2 * time.Hour / time.Second) // 2 hours (7200 seconds)
const loginCsrfCookieName = "login_csrf"

// CreateLoginState creates a new cookie/state pair for the login process and stores it into the DB.
// Returns the generated cookie/state pair.
func CreateLoginState(s *database.LoginStateStore, conf *config.Server) (*http.Cookie, string, error) {
	var state string
	state, err := GenerateKey()
	if err != nil {
		return nil, "", err
	}
	var cookie string
	err = s.RetryOnDuplicatePrimaryKeyError(func(retryStore *database.DataStore) error {
		cookie, err = GenerateKey()
		if err != nil {
			return err
		}
		return retryStore.LoginStates().InsertMap(map[string]interface{}{
			"sCookie":         cookie,
			"sState":          state,
			"sExpirationDate": gorm.Expr("? + INTERVAL ? SECOND", database.Now(), loginStateLifetimeInSeconds),
		})
	})
	if err != nil {
		return nil, "", err
	}
	return &http.Cookie{
		Name:    loginCsrfCookieName,
		Value:   cookie,
		Expires: time.Now().Add(time.Duration(loginStateLifetimeInSeconds) * time.Second),
		MaxAge:  int(loginStateLifetimeInSeconds),
		Domain:  conf.Domain, Path: conf.RootPath,
		HttpOnly: true,
	}, state, nil
}

// LoginState represents a login state
type LoginState struct {
	ok     bool
	cookie string
}

// IsOK tells if the login state is valid
func (l *LoginState) IsOK() bool {
	return l.ok
}

// Delete deletes the login state from the DB and
// returns an expired login state cookie with empty value (for wiping the cookie out)
func (l *LoginState) Delete(s *database.LoginStateStore, conf *config.Server) (*http.Cookie, error) {
	if l.ok {
		if err := s.Delete("sCookie = ?", l.cookie).Error(); err != nil {
			return nil, err
		}
	}
	return &http.Cookie{
		Name:    loginCsrfCookieName,
		Value:   "",
		Expires: time.Now().Add(-24 * 365 * time.Hour),
		MaxAge:  -1, // means "Max-Age: 0" :/
		Domain:  conf.Domain, Path: conf.RootPath,
		HttpOnly: true,
	}, nil
}

// LoadLoginState retrieves an expected state value from the DB (using the cookie as a key)
// and compares it with the given state value
func LoadLoginState(s *database.LoginStateStore, r *http.Request, state string) (*LoginState, error) {
	cookie, err := r.Cookie(loginCsrfCookieName)
	if err == http.ErrNoCookie {
		return &LoginState{ok: false}, nil
	}

	var stateFromDB []string
	err = s.Where("sCookie = ?", cookie.Value).Where("sExpirationDate > NOW()").
		Limit(1).Pluck("sState", &stateFromDB).Error()
	if err != nil {
		return &LoginState{ok: false}, err
	}
	if len(stateFromDB) == 0 || stateFromDB[0] != state {
		return &LoginState{ok: false}, nil
	}
	return &LoginState{ok: true, cookie: cookie.Value}, nil
}
