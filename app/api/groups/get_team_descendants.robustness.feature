Feature: List team descendants of the group (groupTeamDescendantView) - robustness
  Background:
    Given the database has the following table 'users':
      | ID | sLogin | idGroupSelf | idGroupOwned |
      | 1  | owner  | 21          | 22           |
      | 2  | user   | 11          | 12           |
    And the database has the following table 'groups_ancestors':
      | idGroupAncestor | idGroupChild | bIsSelf |
      | 11              | 11           | 1       |
      | 12              | 12           | 1       |
      | 13              | 13           | 1       |
      | 21              | 21           | 1       |
      | 22              | 13           | 0       |
      | 22              | 22           | 1       |

  Scenario: User is not an admin of the group
    Given I am the user with ID "2"
    When I send a GET request to "/groups/13/team-descendants"
    Then the response code should be 403
    And the response error message should contain "Insufficient access rights"

  Scenario: Group ID is incorrect
    Given I am the user with ID "1"
    When I send a GET request to "/groups/abc/team-descendants"
    Then the response code should be 400
    And the response error message should contain "Wrong value for group_id (should be int64)"

  Scenario: User not found
    Given I am the user with ID "404"
    When I send a GET request to "/groups/13/team-descendants"
    Then the response code should be 401
    And the response error message should contain "Invalid access token"

  Scenario: sort is incorrect
    Given I am the user with ID "1"
    When I send a GET request to "/groups/13/team-descendants?sort=myname"
    Then the response code should be 400
    And the response error message should contain "Unallowed field in sorting parameters: "myname""
