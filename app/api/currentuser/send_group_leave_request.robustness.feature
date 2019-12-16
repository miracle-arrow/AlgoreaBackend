Feature: User sends a request to leave a group - robustness
  Background:
    Given the database has the following table 'groups':
      | id | require_lock_membership_approval_until |
      | 11 | 2019-05-30 11:00:00                    |
      | 14 | null                                   |
      | 21 | null                                   |
      | 22 | null                                   |
    And the database has the following table 'users':
      | group_id | login |
      | 21       | john  |
      | 22       | jane  |
    And the database has the following table 'groups_groups':
      | parent_group_id | child_group_id | lock_membership_approved_at |
      | 11              | 21             | null                        |
      | 14              | 22             | 2019-05-30 11:00:00         |
    And the database has the following table 'groups_ancestors':
      | ancestor_group_id | child_group_id | is_self |
      | 11                | 11             | 1       |
      | 11                | 21             | 0       |
      | 14                | 14             | 1       |
      | 14                | 21             | 0       |
      | 21                | 21             | 1       |
    And the database has the following table 'group_pending_requests':
      | group_id | member_id | type          | at                  |
      | 14       | 21        | leave_request | 2019-05-30 11:00:00 |

  Scenario: User tries to send a leave request while not being a member of the group
    Given I am the user with id "21"
    When I send a POST request to "/current-user/group-leave-requests/14"
    Then the response code should be 403
    And the response error message should contain "User is not a member of the group or the group doesn't require approval for leaving"
    And the table "groups_groups" should stay unchanged
    And the table "group_pending_requests" should stay unchanged
    And the table "group_membership_changes" should be empty
    And the table "groups_ancestors" should stay unchanged

  Scenario: User tries to send a leave request while groups_groups.lock_membership_approved_at is null
    Given I am the user with id "21"
    When I send a POST request to "/current-user/group-leave-requests/11"
    Then the response code should be 403
    And the response error message should contain "User is not a member of the group or the group doesn't require approval for leaving"
    And the table "group_pending_requests" should stay unchanged
    And the table "group_membership_changes" should be empty
    And the table "groups_ancestors" should stay unchanged

  Scenario: User tries to send a leave request while groups.require_lock_membership_approval_until is null
    Given I am the user with id "22"
    When I send a POST request to "/current-user/group-leave-requests/14"
    Then the response code should be 403
    And the response error message should contain "User is not a member of the group or the group doesn't require approval for leaving"
    And the table "groups_groups" should stay unchanged
    And the table "group_pending_requests" should stay unchanged
    And the table "group_membership_changes" should be empty
    And the table "groups_ancestors" should stay unchanged

  Scenario: Fails when the group id is wrong
    Given I am the user with id "21"
    When I send a POST request to "/current-user/group-leave-requests/abc"
    Then the response code should be 400
    And the response error message should contain "Wrong value for group_id (should be int64)"
    And the table "groups_groups" should stay unchanged
    And the table "group_pending_requests" should stay unchanged
    And the table "group_membership_changes" should be empty
    And the table "groups_ancestors" should stay unchanged
