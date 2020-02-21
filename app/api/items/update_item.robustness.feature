Feature: Update item - robustness
  Background:
    Given the database has the following users:
      | login | temp_user | group_id |
      | jdoe  | 0         | 11       |
    And the database has the following table 'items':
      | id | default_language_tag |
      | 4  | fr                   |
      | 21 | fr                   |
      | 22 | fr                   |
      | 50 | fr                   |
      | 60 | fr                   |
    And the database has the following table 'items_items':
      | parent_item_id | child_item_id | child_order |
      | 4              | 21            | 0           |
      | 21             | 50            | 0           |
    And the database has the following table 'items_ancestors':
      | ancestor_item_id | child_item_id |
      | 4                | 21            |
      | 21               | 50            |
    And the database has the following table 'permissions_generated':
      | group_id | item_id | can_view_generated | can_edit_generated | is_owner_generated |
      | 11       | 4       | solution           | none               | false              |
      | 11       | 21      | solution           | none               | false              |
      | 11       | 22      | none               | children           | false              |
      | 11       | 50      | solution           | all                | false              |
    And the database has the following table 'permissions_granted':
      | group_id | item_id | can_view | can_edit | is_owner | source_group_id |
      | 11       | 4       | solution | none     | false    | 11              |
      | 11       | 21      | solution | none     | false    | 11              |
      | 11       | 50      | solution | all      | false    | 11              |
    And the database has the following table 'groups_ancestors':
      | ancestor_group_id | child_group_id |
      | 11                | 11             |
    And the database has the following table 'languages':
      | tag |
      | sl  |

  Scenario Outline: Wrong field value
    Given I am the user with id "11"
    When I send a PUT request to "/items/50" with the following body:
      """
      {
        "<field>": <value>
      }
      """
    Then the response code should be 400
    And the response body should be, in JSON:
      """
      {
        "success": false,
        "message": "Bad Request",
        "error_text": "Invalid input data",
        "errors":{
          "<field>": ["<error>"]
        }
      }
      """
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged
  Examples:
    | field                      | value         | error                                                                              |
    | default_language_tag       | 1234          | expected type 'string', got unconvertible type 'float64'                           |
    | default_language_tag       | "unknown"     | default_language_tag must be a maximum of 6 characters in length                   |
    | default_language_tag       | ""            | default_language_tag must be at least 1 character in length                        |
    | default_language_tag       | "unknow"      | default language should exist and there should be item's strings in this language  |
    | default_language_tag       | "sl"          | default language should exist and there should be item's strings in this language  | # no strings for the tag
    | full_screen                | "wrong value" | full_screen must be one of [forceYes forceNo default]                              |
    | type                       | "Wrong"       | type must be one of [Chapter Task Course]                                          |
    | validation_type            | "Wrong"       | validation_type must be one of [None All AllButOne Categories One Manual]          |
    | contest_entering_condition | "Wrong"       | contest_entering_condition must be one of [All Half One None]                      |
    | duration                   | "12:34"       | invalid duration                                                                   |
    | duration                   | "-1:34:56"    | invalid duration                                                                   |
    | duration                   | "839:34:56"   | invalid duration                                                                   |
    | duration                   | "99:-1:56"    | invalid duration                                                                   |
    | duration                   | "99:60:56"    | invalid duration                                                                   |
    | duration                   | "99:59:-1"    | invalid duration                                                                   |
    | duration                   | "99:59:60"    | invalid duration                                                                   |

  Scenario: Invalid item_id
    And I am the user with id "11"
    When I send a PUT request to "/items/abc" with the following body:
      """
      {
        "type": "Course"
      }
      """
    Then the response code should be 400
    And the response error message should contain "Wrong value for item_id (should be int64)"
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: The user doesn't exist
    And I am the user with id "121"
    When I send a PUT request to "/items/50" with the following body:
      """
      {
        "type": "Course"
      }
      """
    Then the response code should be 401
    And the response error message should contain "Invalid access token"
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: The user doesn't have rights to edit the item
    And I am the user with id "11"
    When I send a PUT request to "/items/60" with the following body:
      """
      {
        "type": "Course"
      }
      """
    Then the response code should be 403
    And the response error message should contain "No access rights to edit the item's properties"
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: The user doesn't have rights to edit the item (can_edit = children)
    And I am the user with id "11"
    When I send a PUT request to "/items/22" with the following body:
      """
      {
        "type": "Course"
      }
      """
    Then the response code should be 403
    And the response error message should contain "No access rights to edit the item's properties"
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: The user doesn't have rights to edit item's children
    And I am the user with id "11"
    When I send a PUT request to "/items/60" with the following body:
      """
      {
        "children": []
      }
      """
    Then the response code should be 403
    And the response error message should contain "No access rights to edit the item's children"
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: Non-unique children item IDs
    Given I am the user with id "11"
    When I send a PUT request to "/items/50" with the following body:
      """
      {
        "children": [
          {"item_id": "21", "order": 1},
          {"item_id": "21", "order": 2}
        ]
      }
      """
    Then the response code should be 400
    And the response body should be, in JSON:
      """
      {
        "success": false,
        "message": "Bad Request",
        "error_text": "Invalid input data",
        "errors":{
          "children": ["children IDs should be unique and each should be visible to the user"]
        }
      }
      """
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: Children items are not visible to the user
    Given I am the user with id "11"
    When I send a PUT request to "/items/50" with the following body:
      """
      {
        "children": [
          {"item_id": "4", "order": 1},
          {"item_id": "22", "order": 2}
        ]
      }
      """
    Then the response code should be 400
    And the response body should be, in JSON:
      """
      {
        "success": false,
        "message": "Bad Request",
        "error_text": "Invalid input data",
        "errors":{
          "children": ["children IDs should be unique and each should be visible to the user"]
        }
      }
      """
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: The item is among child items
    Given I am the user with id "11"
    When I send a PUT request to "/items/50" with the following body:
      """
      {
        "children": [
          {"item_id": "50", "order": 1}
        ]
      }
      """
    Then the response code should be 403
    And the response error message should contain "An item cannot become an ancestor of itself"
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario: The item is a descendant of a child item
    Given I am the user with id "11"
    When I send a PUT request to "/items/50" with the following body:
      """
      {
        "children": [
          {"item_id": "21", "order": 1}
        ]
      }
      """
    Then the response code should be 403
    And the response error message should contain "An item cannot become an ancestor of itself"
    And the table "items" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "permissions_granted" should stay unchanged

  Scenario Outline: Not enough permissions for setting propagation in items_items
    Given I am the user with id "11"
    And the database table 'items' has also the following row:
      | id | default_language_tag |
      | 90 | fr                   |
    And the database table 'permissions_generated' has also the following row:
      | group_id | item_id | <permission_column> | can_view_generated |
      | 11       | 90      | <permission_value>  | info               |
    When I send a PUT request to "/items/50" with the following body:
      """
      {
        "children": [{
          "item_id": "90",
          "order": 1,
          "<field>": {{"<value>" != "true" && "<value>" != "false" ? "\"<value>\"" : <value>}}
        }]
      }
      """
    Then the response code should be 403
    And the response body should be, in JSON:
      """
      {
        "success": false,
        "message": "Forbidden",
        "error_text": "<error>"
      }
      """
    And the table "items" should stay unchanged
    And the table "items_items" should stay unchanged
    And the table "items_ancestors" should stay unchanged
    And the table "items_strings" should stay unchanged
    And the table "permissions_granted" should stay unchanged
    And the table "permissions_generated" should stay unchanged
    Examples:
      | field                         | value                       | permission_column        | permission_value         | error                                                            |
      | content_view_propagation      | as_content                  | can_grant_view_generated | none                     | Not enough permissions for setting content_view_propagation      |
      | content_view_propagation      | as_info                     | can_grant_view_generated | none                     | Not enough permissions for setting content_view_propagation      |
      | upper_view_levels_propagation | as_is                       | can_grant_view_generated | content_with_descendants | Not enough permissions for setting upper_view_levels_propagation |
      | upper_view_levels_propagation | as_content_with_descendants | can_grant_view_generated | content                  | Not enough permissions for setting upper_view_levels_propagation |
      | grant_view_propagation        | true                        | can_grant_view_generated | solution                 | Not enough permissions for setting grant_view_propagation        |
      | watch_propagation             | true                        | can_watch_generated      | answer                   | Not enough permissions for setting watch_propagation             |
      | edit_propagation              | true                        | can_edit_generated       | all                      | Not enough permissions for setting edit_propagation             |
