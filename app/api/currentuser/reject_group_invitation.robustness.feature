Feature: User rejects an invitation to join a group - robustness
  Background:
    Given the database has the following table 'users':
      | id | self_group_id | owned_group_id | login |
      | 1  | 21            | 22             | john  |
      | 2  | null          | null           | guest |
    And the database has the following table 'groups':
      | id |
      | 11 |
      | 14 |
      | 21 |
      | 22 |
    And the database has the following table 'groups_ancestors':
      | ancestor_group_id | child_group_id | is_self |
      | 11                | 11             | 1       |
      | 14                | 14             | 1       |
      | 21                | 21             | 1       |
      | 22                | 22             | 1       |
    And the database has the following table 'groups_groups':
      | id | parent_group_id | child_group_id | type           | status_changed_at   |
      | 1  | 11              | 21             | requestSent    | 2017-04-29 06:38:38 |
      | 2  | 13              | 21             | invitationSent | 2017-03-29 06:38:38 |

  Scenario: User tries to reject an invitation that doesn't exist
    Given I am the user with id "1"
    When I send a POST request to "/current-user/group-invitations/11/reject"
    Then the response code should be 404
    And the response body should be, in JSON:
    """
    {
      "success": false,
      "message": "Not Found",
      "error_text": "No such relation"
    }
    """
    And the table "groups_groups" should stay unchanged
    And the table "groups_ancestors" should stay unchanged

  Scenario: Fails when the group id is wrong
    Given I am the user with id "1"
    When I send a POST request to "/current-user/group-invitations/abc/reject"
    Then the response code should be 400
    And the response error message should contain "Wrong value for group_id (should be int64)"
    And the table "groups_groups" should stay unchanged
    And the table "groups_ancestors" should stay unchanged

  Scenario: Fails when the user's self_group_id is NULL
    Given I am the user with id "2"
    When I send a POST request to "/current-user/group-invitations/14/reject"
    Then the response code should be 403
    And the response error message should contain "Insufficient access rights"
    And the table "groups_groups" should stay unchanged
    And the table "groups_ancestors" should stay unchanged

  Scenario: Fails if the user doesn't exist
    Given I am the user with id "4"
    When I send a POST request to "/current-user/group-invitations/13/reject"
    Then the response code should be 401
    And the response error message should contain "Invalid access token"

