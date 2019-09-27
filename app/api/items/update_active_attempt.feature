Feature: Update active attempt for an item
  Background:
    Given the database has the following table 'users':
      | id | login | self_group_id |
      | 10 | john  | 101           |
      | 11 | jane  | 111           |
      | 12 | jack  | 121           |
    And the database has the following table 'groups':
      | id  | team_item_id | type     |
      | 101 | null         | UserSelf |
      | 102 | 10           | Team     |
      | 111 | null         | UserSelf |
    And the database has the following table 'groups_groups':
      | parent_group_id | child_group_id | type               |
      | 102             | 101            | invitationAccepted |
      | 102             | 121            | joinedByCode       |
      | 103             | 101            | requestAccepted    |
      | 104             | 101            | direct             |
    And the database has the following table 'groups_ancestors':
      | ancestor_group_id | child_group_id | is_self |
      | 101               | 101            | 1       |
      | 102               | 101            | 0       |
      | 102               | 102            | 1       |
      | 102               | 121            | 0       |
      | 111               | 111            | 1       |
      | 121               | 121            | 1       |
    And the database has the following table 'items':
      | id | url                                                                     | type    | has_attempts |
      | 10 | null                                                                    | Chapter | 0            |
      | 50 | http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936 | Course  | 0            |
      | 60 | http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936 | Task    | 1            |
    And the database has the following table 'items_ancestors':
      | ancestor_item_id | child_item_id |
      | 10               | 60            |
    And the database has the following table 'items_items':
      | parent_item_id | child_item_id | child_order |
      | 10             | 60            | 0           |
    And the database has the following table 'groups_items':
      | group_id | item_id | cached_partial_access_since | cached_full_access_since | creator_user_id |
      | 101      | 50      | 2017-05-29 06:38:38         | null                     | 10              |
      | 101      | 60      | 2017-05-29 06:38:38         | null                     | 10              |
      | 111      | 50      | null                        | 2017-05-29 06:38:38      | 10              |
      | 121      | 50      | null                        | 2017-05-29 06:38:38      | 10              |

  Scenario: User is able to update an active attempt (full access)
    Given I am the user with id "11"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 11      | 50      | null              | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 100 | 111      | 50      | 2017-05-29 06:38:38 | 0     |
    When I send a PUT request to "/attempts/100/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 11      | 50      | 100               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 100 | 111      | 50      | done                        | 1                                                       |

  Scenario: User is able to fetch an active attempt (partial access)
    Given I am the user with id "10"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 10      | 50      | null              | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 100 | 101      | 50      | 2017-05-29 06:38:38 | 0     |
    When I send a PUT request to "/attempts/100/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 10      | 50      | 100               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 100 | 101      | 50      | done                        | 1                                                       |

  Scenario: User is able to update an active attempt (full access, groups_groups.type=joinedByCode)
    Given I am the user with id "11"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 11      | 50      | null              | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 100 | 111      | 50      | 2017-05-29 06:38:38 | 0     |
    When I send a PUT request to "/attempts/100/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 11      | 50      | 100               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 100 | 111      | 50      | done                        | 1                                                       |

  Scenario: User is able to update an active attempt (has_attempts=1, groups_groups.type=invitationAccepted)
    Given I am the user with id "10"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 10      | 10      | null              | 2018-05-29 06:38:38 |
      | 10      | 60      | null              | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 200 | 102      | 60      | 2017-05-29 06:38:38 | 0     |
    When I send a PUT request to "/attempts/200/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 10      | 10      | null              | done                        | 1                                                       |
      | 10      | 60      | 200               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 200 | 102      | 60      | done                        | 1                                                       |

  Scenario: User is able to update an active attempt (has_attempts=1, groups_groups.type=requestAccepted)
    Given I am the user with id "10"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 10      | 10      | null              | 2018-05-29 06:38:38 |
      | 10      | 60      | null              | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 200 | 103      | 60      | 2017-05-29 06:38:38 | 0     |
    When I send a PUT request to "/attempts/200/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 10      | 10      | null              | done                        | 1                                                       |
      | 10      | 60      | 200               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 200 | 103      | 60      | done                        | 1                                                       |

  Scenario: User is able to update an active attempt (has_attempts=1, groups_groups.type=direct)
    Given I am the user with id "10"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 10      | 10      | null              | 2018-05-29 06:38:38 |
      | 10      | 60      | null              | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 200 | 104      | 60      | 2017-05-29 06:38:38 | 0     |
    When I send a PUT request to "/attempts/200/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 10      | 10      | null              | done                        | 1                                                       |
      | 10      | 60      | 200               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 200 | 104      | 60      | done                        | 1                                                       |

  Scenario: User is able to update an active attempt when this attempt is already active
    Given I am the user with id "11"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 11      | 50      | 100               | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 100 | 111      | 50      | 2017-05-29 06:38:38 | 0     |
    When I send a PUT request to "/attempts/100/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 11      | 50      | 100               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 100 | 111      | 50      | done                        | 1                                                       |


  Scenario: User is able to update an active attempt when another attempt is active
    Given I am the user with id "11"
    And the database has the following table 'users_items':
      | user_id | item_id | active_attempt_id | last_activity_at    |
      | 11      | 50      | 101               | 2017-05-29 06:38:38 |
    And the database has the following table 'groups_attempts':
      | id  | group_id | item_id | last_activity_at    | order |
      | 100 | 111      | 50      | 2017-05-29 06:38:38 | 0     |
      | 101 | 111      | 50      | 2018-05-29 06:38:38 | 1     |
    When I send a PUT request to "/attempts/100/active"
    Then the response code should be 200
    And the response body should be, in JSON:
      """
      {
        "message": "updated",
        "success": true
      }
      """
    And the table "users_items" should be:
      | user_id | item_id | active_attempt_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 11      | 50      | 100               | done                        | 1                                                       |
    And the table "groups_attempts" should be:
      | id  | group_id | item_id | ancestors_computation_state | ABS(TIMESTAMPDIFF(SECOND, last_activity_at, NOW())) < 3 |
      | 100 | 111      | 50      | done                        | 1                                                       |
      | 101 | 111      | 50      | done                        | 0                                                       |
