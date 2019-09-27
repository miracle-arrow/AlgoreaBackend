Feature: Discard the code of the given group

  Background:
    Given the database has the following table 'users':
      | id | login | temp_user | self_group_id | owned_group_id | first_name  | last_name | default_language |
      | 1  | owner | 0         | 21            | 22             | Jean-Michel | Blanquer  | fr               |
    And the database has the following table 'groups':
      | id | name    | grade | description     | created_at          | type      | code       | code_timer | code_expires_at     |
      | 11 | Group A | -3    | Group A is here | 2019-02-06 09:26:40 | Class     | ybqybxnlyo | 01:00:00   | 2017-10-13 05:39:48 |
      | 13 | Group B | -2    | Group B is here | 2019-03-06 09:26:40 | Class     | 3456789abc | 01:00:00   | 2017-10-14 05:39:48 |
      | 14 | Group C | -4    | Admin Group     | 2019-04-06 09:26:40 | UserAdmin | null       | null       | null                |
    And the database has the following table 'groups_ancestors':
      | id | ancestor_group_id | child_group_id | is_self | version |
      | 75 | 22                | 13             | 0       | 0       |
      | 76 | 13                | 11             | 0       | 0       |
      | 77 | 22                | 11             | 0       | 0       |
      | 78 | 21                | 21             | 1       | 0       |

  Scenario: User is an admin of the group
    Given I am the user with id "1"
    When I send a DELETE request to "/groups/13/code"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    {
      "success": true,
      "message": "deleted"
    }
    """
    And the table "groups" should stay unchanged but the row with id "13"
    And the table "groups" at id "13" should be:
      | id | name    | grade | description     | created_at          | type  | code | code_timer | code_expires_at     |
      | 13 | Group B | -2    | Group B is here | 2019-03-06 09:26:40 | Class | null | 01:00:00   | 2017-10-14 05:39:48 |
