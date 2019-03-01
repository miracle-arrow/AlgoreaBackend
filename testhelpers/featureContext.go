package testhelpers

import (
	"github.com/DATA-DOG/godog"
)

// FeatureContext binds the supported steps to the verifying functions
func FeatureContext(s *godog.Suite) {
	ctx := &TestContext{}
	s.BeforeScenario(ctx.SetupTestContext)

	s.Step(`^the database has the following table \'([\w\-_]*)\':$`, ctx.DBHasTable)
	s.Step(`^a server is running as fallback$`, ctx.RunFallbackServer)
	s.Step(`^I am the user with ID "([^"]*)"$`, ctx.IAmUserWithID)
	s.Step(`^the time now is "([^"]*)"$`, ctx.TimeNow)

	s.Step(`^I send a (GET|POST|PUT|DELETE) request to "([^"]*)"$`, ctx.ISendrequestTo)
	s.Step(`^I send a (GET|POST|PUT|DELETE) request to "([^"]*)" with the following body:$`, ctx.ISendrequestToWithBody)
	s.Step(`^the response code should be (\d+)$`, ctx.TheResponseCodeShouldBe)
	s.Step(`^the response body should be, in JSON:$`, ctx.TheResponseBodyShouldBeJSON)
	s.Step(`^the response header "([^"]*)" should be "([^"]*)"$`, ctx.TheResponseHeaderShouldBe)
	s.Step(`^the response error message should contain "([^"]*)"$`, ctx.TheResponseErrorMessageShouldContain)
	s.Step(`^it should be a JSON array with (\d+) entr(ies|y)$`, ctx.ItShouldBeAJSONArrayWithEntries)
	s.Step(`^the table "([^"]*)" should be:$`, ctx.TableShouldBe)
	s.Step(`^the table "([^"]*)" at ID "(\d*)" should be:$`, ctx.TableAtIDShouldBe)

	s.AfterScenario(ctx.ScenarioTeardown)
}