Feature: Delete the current user - robustness
  Background:
    Given the DB time now is "2019-08-09 23:59:59"
    And the database has the following table 'groups':
      | id | type     | name      | require_lock_membership_approval_until |
      | 1  | Base     | Root      | null                                   |
      | 2  | Base     | RootSelf  | null                                   |
      | 4  | Base     | RootTemp  | null                                   |
      | 21 | UserSelf | user      | null                                   |
      | 50 | Class    | Our class | 2019-08-10 00:00:00                    |
    And the database has the following table 'groups_groups':
      | parent_group_id | child_group_id | lock_membership_approved_at |
      | 1               | 2              | null                        |
      | 1               | 50             | null                        |
      | 2               | 4              | null                        |
      | 2               | 21             | null                        |
      | 50              | 21             | 2019-05-30 11:00:00         |
    And the database has the following table 'groups_ancestors':
      | ancestor_group_id | child_group_id | is_self |
      | 1                 | 1              | true    |
      | 1                 | 2              | false   |
      | 1                 | 4              | false   |
      | 1                 | 21             | false   |
      | 1                 | 50             | false   |
      | 2                 | 2              | true    |
      | 2                 | 4              | false   |
      | 2                 | 21             | false   |
      | 4                 | 4              | true    |
      | 21                | 21             | true    |
      | 50                | 21             | false   |
      | 50                | 50             | true    |
    And the database has the following table 'users':
      | temp_user | login | group_id | login_id |
      | 0         | user  | 21       | 1234567  |
    And the application config is:
      """
      auth:
        loginModuleURL: "https://login.algorea.org"
        clientID: "1"
        clientSecret: "tzxsLyFtJiGnmD6sjZMqSEidVpVsL3hEoSxIXCpI"
        callbackURL: "https://backend.algorea.org/auth/login-callback"
      """

  Scenario: User cannot delete himself right now
    Given I am the user with id "21"
    When I send a DELETE request to "/current-user"
    Then the response code should be 403
    And the response error message should contain "You cannot delete yourself right now"
    And logs should contain:
      """
      A user with group_id = 21 tried to delete himself, but he is a member of a group with lock_user_deletion_until >= NOW()
      """
    And the table "users" should stay unchanged
    And the table "groups" should stay unchanged
    And the table "groups_groups" should stay unchanged
    And the table "groups_ancestors" should stay unchanged

  Scenario: Login module fails
    Given I am the user with id "21"
    And the DB time now is "2019-08-10 00:00:00"
    And the login module "unlink_client" endpoint for user id "1234567" returns 500 with encoded body:
      """
      {"success":false}
      """
    When I send a DELETE request to "/current-user"
    Then the response code should be 500
    And the response error message should contain "Can't unlink the user"
    And the table "users" should be empty
    And the table "groups" should be:
      | id | type  | name      | require_lock_membership_approval_until |
      | 1  | Base  | Root      | null                                   |
      | 2  | Base  | RootSelf  | null                                   |
      | 4  | Base  | RootTemp  | null                                   |
      | 50 | Class | Our class | 2019-08-10 00:00:00                    |
    And the table "groups_groups" should be:
      | parent_group_id | child_group_id |
      | 1               | 2              |
      | 1               | 50             |
      | 2               | 4              |
    And the table "groups_ancestors" should be:
      | ancestor_group_id | child_group_id | is_self |
      | 1                 | 1              | true    |
      | 1                 | 2              | false   |
      | 1                 | 4              | false   |
      | 1                 | 50             | false   |
      | 2                 | 2              | true    |
      | 2                 | 4              | false   |
      | 4                 | 4              | true    |
      | 50                | 50             | true    |
