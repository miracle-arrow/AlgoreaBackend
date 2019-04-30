package currentuser

import (
	"github.com/go-chi/chi"
	"github.com/go-chi/render"

	"github.com/France-ioi/AlgoreaBackend/app/auth"
	"github.com/France-ioi/AlgoreaBackend/app/service"
)

// Service is the mount point for services related to `items`
type Service struct {
	service.Base
}

// SetRoutes defines the routes for this package in a route group
func (srv *Service) SetRoutes(router chi.Router) {
	router.Use(render.SetContentType(render.ContentTypeJSON))
	router.Use(auth.UserIDMiddleware(&srv.Config.Auth))

	router.Get("/current-user", service.AppHandler(srv.getInfo).ServeHTTP)

	router.Get("/current-user/invitations", service.AppHandler(srv.getInvitations).ServeHTTP)
	router.Get("/current-user/memberships", service.AppHandler(srv.getMemberships).ServeHTTP)
}