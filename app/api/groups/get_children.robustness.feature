Feature: Get group children (groupChildrenView) - robustness
  Background:
    Given the database has the following table 'users':
      | ID | sLogin | tempUser | idGroupSelf | idGroupOwned | sFirstName  | sLastName | sDefaultLanguage |
      | 1  | owner  | 0        | 21          | 22           | Jean-Michel | Blanquer  | fr               |
    And the database has the following table 'groups_ancestors':
      | ID | idGroupAncestor | idGroupChild | bIsSelf | iVersion |
      | 75 | 22              | 13           | 0       | 0        |
    And the database has the following table 'groups':
      | ID | sName       | iGrade | sType     | bOpened | bFreeAccess | sPassword  |
      | 11 | Group A     | -3     | Class     | true    | true        | ybqybxnlyo |
      | 13 | Group B     | -2     | Class     | true    | true        | ybabbxnlyo |

  Scenario: User is not an owner of the parent group
    Given I am the user with ID "1"
    When I send a GET request to "/groups/11/children"
    Then the response code should be 403
    And the response error message should contain "Insufficient access rights"

  Scenario: User doesn't exist
    Given I am the user with ID "10"
    When I send a GET request to "/groups/11/children"
    Then the response code should be 403
    And the response error message should contain "Insufficient access rights"

  Scenario: Invalid group_id given
    Given I am the user with ID "1"
    When I send a GET request to "/groups/1_1/children"
    Then the response code should be 400
    And the response error message should contain "Wrong value for group_id (should be int64)"

  Scenario: Invalid sorting rules given
    Given I am the user with ID "1"
    When I send a GET request to "/groups/13/children?sort=password"
    Then the response code should be 400
    And the response error message should contain "Unallowed field in sorting parameters: "password""

  Scenario: Invalid type in types_include
    Given I am the user with ID "1"
    When I send a GET request to "/groups/13/children?types_include=Teacher"
    Then the response code should be 400
    And the response error message should contain "Wrong value in 'types_include': "Teacher""

  Scenario: Invalid type in types_exclude
    Given I am the user with ID "1"
    When I send a GET request to "/groups/13/children?types_exclude=Manager"
    Then the response code should be 400
    And the response error message should contain "Wrong value in 'types_exclude': "Manager""
