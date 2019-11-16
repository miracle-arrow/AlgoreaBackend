Feature: Add item

  Background:
    Given the database has the following table 'groups':
      | id | name       | type      |
      | 11 | jdoe       | UserSelf  |
      | 12 | jdoe-admin | UserAdmin |
    And the database has the following table 'users':
      | login | temp_user | group_id | owned_group_id |
      | jdoe  | 0         | 11       | 12             |
    And the database has the following table 'items':
      | id | teams_editable | no_score |
      | 21 | false          | false    |
    And the database has the following table 'permissions_generated':
      | group_id | item_id | can_view_generated | can_edit_generated |
      | 11       | 21      | solution           | children           |
    And the database has the following table 'permissions_granted':
      | group_id | item_id | can_view | can_edit | giver_group_id | latest_update_on    |
      | 11       | 21      | solution | children | 11             | 2019-05-30 11:00:00 |
    And the database has the following table 'groups_ancestors':
      | id | ancestor_group_id | child_group_id | is_self |
      | 71 | 11                | 11             | 1       |
      | 72 | 12                | 12             | 1       |
    And the database has the following table 'languages':
      | id |
      | 3  |

  Scenario: Valid
    Given I am the user with id "11"
    When I send a POST request to "/items" with the following body:
      """
      {
        "type": "Course",
        "language_id": "3",
        "title": "my title",
        "image_url":"http://bit.ly/1234",
        "subtitle": "hard task",
        "description": "the goal of this task is ...",
        "parent_item_id": "21",
        "order": 100
      }
      """
    Then the response code should be 201
    And the response body should be, in JSON:
      """
      {
        "success": true,
        "message": "created",
        "data": { "id": "5577006791947779410" }
      }
      """
    And the table "items" at id "5577006791947779410" should be:
      | id                  | type   | url  | default_language_id | teams_editable | no_score | text_id | title_bar_visible | custom_chapter | display_details_in_parent | uses_api | read_only | full_screen | show_difficulty | show_source | hints_allowed | fixed_ranks | validation_type | validation_min | unlocked_item_ids | score_min_unlock | contest_entering_condition | teams_editable | contest_max_team_size | has_attempts | duration | show_user_infos | contest_phase | level | no_score | group_code_enter |
      | 5577006791947779410 | Course | null | 3                   | 0              | 0        | null    | 1                 | 0              | 0                         | 1        | 0         | default     | 0               | 0           | 0             | 0           | All             | null           | null              | 100              | None                       | 0              | 0                     | 0            | null     | 0               | Running       | null  | 0        | 0                |
    And the table "items_strings" should be:
      | id                  | item_id             | language_id | title    | image_url          | subtitle  | description                  |
      | 8674665223082153551 | 5577006791947779410 | 3           | my title | http://bit.ly/1234 | hard task | the goal of this task is ... |
    And the table "items_items" should be:
      | id                  | parent_item_id | child_item_id       | child_order | content_view_propagation | upper_view_levels_propagation | grant_view_propagation | watch_propagation | edit_propagation |
      | 6129484611666145821 | 21             | 5577006791947779410 | 100         | as_info                  | as_is                         | 1                      | 1                 | 1                |
    And the table "items_ancestors" should be:
      | ancestor_item_id | child_item_id       |
      | 21               | 5577006791947779410 |
    And the table "permissions_granted" at group_id "11" should be:
      | group_id | item_id             | giver_group_id | can_view | can_grant_view | can_watch | can_edit | is_owner | ABS(TIMESTAMPDIFF(SECOND, latest_update_on, NOW())) < 3 |
      | 11       | 21                  | 11             | solution | none           | none      | children | 0        | 0                                                       |
      | 11       | 5577006791947779410 | 11             | none     | none           | none      | none     | 1        | 1                                                       |
    And the table "permissions_generated" should be:
      | group_id | item_id             | can_view_generated | can_grant_view_generated | can_watch_generated | can_edit_generated | is_owner_generated |
      | 11       | 21                  | solution           | none                     | none                | children           | 0                  |
      | 11       | 5577006791947779410 | solution           | transfer                 | transfer            | transfer           | 1                  |

  Scenario: Valid (all the fields are set)
    Given I am the user with id "11"
    And the database table 'groups' has also the following rows:
      | id    |
      | 12345 |
    And the database has the following table 'groups_ancestors':
      | id | ancestor_group_id | child_group_id | is_self |
      | 73 | 12                | 12345          | 0       |
    And the database table 'items' has also the following rows:
      | id |
      | 12 |
      | 34 |
    And the database table 'permissions_generated' has also the following rows:
      | group_id | item_id | can_view_generated       | can_grant_view_generated | can_watch_generated | can_edit_generated | is_owner_generated |
      | 11       | 12      | content_with_descendants | solution                 | answer              | all                | 0                  |
      | 11       | 34      | solution                 | transfer                 | transfer            | transfer           | 0                  |
    And the database table 'permissions_granted' has also the following rows:
      | group_id | item_id | can_view                 | can_grant_view | can_watch | can_edit | is_owner | giver_group_id | latest_update_on    |
      | 11       | 12      | content_with_descendants | solution       | answer    | all      | 0        | 11             | 2019-05-30 11:00:00 |
      | 11       | 34      | solution                 | transfer       | transfer  | transfer | 0        | 11             | 2019-05-30 11:00:00 |
    When I send a POST request to "/items" with the following body:
      """
      {
        "type": "Course",
        "url": "http://myurl.com/",
        "text_id": "Task number 1",
        "title_bar_visible": true,
        "custom_chapter": true,
        "display_details_in_parent": true,
        "uses_api": true,
        "read_only": true,
        "full_screen": "forceYes",
        "show_difficulty": true,
        "show_source": true,
        "hints_allowed": true,
        "fixed_ranks": true,
        "validation_type": "AllButOne",
        "validation_min": 1234,
        "unlocked_item_ids": "12,34",
        "score_min_unlock": 34,
        "contest_entering_condition": "All",
        "teams_editable": true,
        "contest_max_team_size": 2345,
        "has_attempts": true,
        "duration": "01:02:03",
        "show_user_infos": true,
        "contest_phase": "Analysis",
        "level": 345,
        "no_score": true,
        "group_code_enter": true,
        "language_id": "3",
        "title": "my title",
        "image_url":"http://bit.ly/1234",
        "subtitle": "hard task",
        "description": "the goal of this task is ...",
        "parent_item_id": "21",
        "order": 100,
        "children": [
          {"item_id": "12", "order": 0},
          {"item_id": "34", "order": 1}
        ]
      }
      """
    Then the response code should be 201
    And the response body should be, in JSON:
      """
      {
        "success": true,
        "message": "created",
        "data": { "id": "5577006791947779410" }
      }
      """
    And the table "items" at id "5577006791947779410" should be:
      | id                  | type   | url               | default_language_id | teams_editable | no_score | text_id       | title_bar_visible | custom_chapter | display_details_in_parent | uses_api | read_only | full_screen | show_difficulty | show_source | hints_allowed | fixed_ranks | validation_type | validation_min | unlocked_item_ids | score_min_unlock | contest_entering_condition | teams_editable | contest_max_team_size | has_attempts | duration | show_user_infos | contest_phase | level | no_score | group_code_enter |
      | 5577006791947779410 | Course | http://myurl.com/ | 3                   | 1              | 1        | Task number 1 | 1                 | 1              | 1                         | 1        | 1         | forceYes    | 1               | 1           | 1             | 1           | AllButOne       | 1234           | 12,34             | 34               | All                        | 1              | 2345                  | 1            | 01:02:03 | 1               | Analysis      | 345   | 1        | 1                |
    And the table "items_strings" should be:
      | id                  | item_id             | language_id | title    | image_url          | subtitle  | description                  |
      | 8674665223082153551 | 5577006791947779410 | 3           | my title | http://bit.ly/1234 | hard task | the goal of this task is ... |
    And the table "items_items" should be:
      | parent_item_id      | child_item_id       | child_order | content_view_propagation | upper_view_levels_propagation | grant_view_propagation | watch_propagation | edit_propagation |
      | 21                  | 5577006791947779410 | 100         | as_info                  | as_is                         | 1                      | 1                 | 1                |
      | 5577006791947779410 | 12                  | 0           | as_info                  | as_content_with_descendants   | 0                      | 0                 | 0                |
      | 5577006791947779410 | 34                  | 1           | as_info                  | as_is                         | 1                      | 1                 | 1                |
    And the table "items_ancestors" should be:
      | ancestor_item_id    | child_item_id       |
      | 21                  | 12                  |
      | 21                  | 34                  |
      | 21                  | 5577006791947779410 |
      | 5577006791947779410 | 12                  |
      | 5577006791947779410 | 34                  |
    And the table "permissions_granted" at group_id "11" should be:
      | group_id | item_id             | giver_group_id | can_view                 | can_grant_view | can_watch | can_edit | is_owner | ABS(TIMESTAMPDIFF(SECOND, latest_update_on, NOW())) < 3 |
      | 11       | 12                  | 11             | content_with_descendants | solution       | answer    | all      | 0        | 0                                                       |
      | 11       | 21                  | 11             | solution                 | none           | none      | children | 0        | 0                                                       |
      | 11       | 34                  | 11             | solution                 | transfer       | transfer  | transfer | 0        | 0                                                       |
      | 11       | 5577006791947779410 | 11             | none                     | none           | none      | none     | 1        | 1                                                       |
    And the table "permissions_generated" should be:
      | group_id | item_id             | can_view_generated       | can_grant_view_generated | can_watch_generated | can_edit_generated | is_owner_generated |
      | 11       | 12                  | content_with_descendants | solution                 | answer              | all                | 0                  |
      | 11       | 21                  | solution                 | none                     | none                | children           | 0                  |
      | 11       | 34                  | solution                 | transfer                 | transfer            | transfer           | 0                  |
      | 11       | 5577006791947779410 | solution                 | transfer                 | transfer            | transfer           | 1                  |

  Scenario: Valid with empty full_screen
    Given I am the user with id "11"
    When I send a POST request to "/items" with the following body:
    """
    {
      "type": "Course",
      "full_screen": "",
      "language_id": "3",
      "title": "my title",
      "parent_item_id": "21",
      "order": 100
    }
    """
    Then the response code should be 201
    And the response body should be, in JSON:
    """
    {
      "success": true,
      "message": "created",
      "data": { "id": "5577006791947779410" }
    }
    """
    And the table "items" at id "5577006791947779410" should be:
      | id                  | type   | url  | default_language_id | teams_editable | no_score | text_id | title_bar_visible | custom_chapter | display_details_in_parent | uses_api | read_only | full_screen | show_difficulty | show_source | hints_allowed | fixed_ranks | validation_type | validation_min | unlocked_item_ids | score_min_unlock | contest_entering_condition | teams_editable | contest_max_team_size | has_attempts | duration | show_user_infos | contest_phase | level | no_score | group_code_enter |
      | 5577006791947779410 | Course | null | 3                   | 0              | 0        | null    | 1                 | 0              | 0                         | 1        | 0         |             | 0               | 0           | 0             | 0           | All             | null           | null              | 100              | None                       | 0              | 0                     | 0            | null     | 0               | Running       | null  | 0        | 0                |
    And the table "items_strings" should be:
      | id                  | item_id             | language_id | title    | image_url | subtitle | description |
      | 8674665223082153551 | 5577006791947779410 | 3           | my title | null      | null     | null        |
    And the table "items_items" should be:
      | id                  | parent_item_id | child_item_id       | child_order | content_view_propagation | upper_view_levels_propagation | grant_view_propagation | watch_propagation | edit_propagation |
      | 6129484611666145821 | 21             | 5577006791947779410 | 100         | as_info                  | as_is                         | 1                      | 1                 | 1                |
    And the table "items_ancestors" should be:
      | ancestor_item_id | child_item_id       |
      | 21               | 5577006791947779410 |
    And the table "permissions_granted" at group_id "11" should be:
      | group_id | item_id             | giver_group_id | can_view | can_grant_view | can_watch | can_edit | is_owner | ABS(TIMESTAMPDIFF(SECOND, latest_update_on, NOW())) < 3 |
      | 11       | 21                  | 11             | solution | none           | none      | children | 0        | 0                                                       |
      | 11       | 5577006791947779410 | 11             | none     | none           | none      | none     | 1        | 1                                                       |
    And the table "permissions_generated" should be:
      | group_id | item_id             | can_view_generated | can_grant_view_generated | can_watch_generated | can_edit_generated | is_owner_generated |
      | 11       | 21                  | solution           | none                     | none                | children           | 0                  |
      | 11       | 5577006791947779410 | solution           | transfer                 | transfer            | transfer           | 1                  |
