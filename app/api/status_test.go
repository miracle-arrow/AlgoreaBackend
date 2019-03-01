package api

import (
	"testing"

	assertlib "github.com/stretchr/testify/assert"

	"github.com/France-ioi/AlgoreaBackend/app/database"
)

func TestDbOk(t *testing.T) {
	assert := assertlib.New(t)
	ctx := &Ctx{config: nil, db: nil, reverseProxy: nil}
	assert.HTTPSuccess(ctx.status, "GET", "", nil)
	assert.HTTPBodyContains(ctx.status, "GET", "", nil, "The web service is responding! The database connection fails.")
}

func TestDbNotOk(t *testing.T) {
	assert := assertlib.New(t)
	dbMock, _ := database.NewDBMock()
	ctx := &Ctx{config: nil, db: dbMock, reverseProxy: nil}
	assert.HTTPSuccess(ctx.status, "GET", "", nil)
	assert.HTTPBodyContains(ctx.status, "GET", "", nil, "The web service is responding! The database connection is established.")
}