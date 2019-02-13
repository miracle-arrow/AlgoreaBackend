Feature: Get item view information - robustness
Background:
  Given the database has the following table 'users':
    | ID | sLogin | tempUser | idGroupSelf | idGroupOwned | iVersion |
    | 1  | jdoe   | 0        | 11          | 12           | 0        |
    | 2  | guest  | 0        | 404         | 404          | 0        |
    | 3  | grayed | 0        | 14          | 15           | 0        |
  And the database has the following table 'groups':
    | ID | sName      | sTextId | iGrade | sType     | iVersion |
    | 11 | jdoe       |         | -2     | UserAdmin | 0        |
    | 12 | jdoe-admin |         | -2     | UserAdmin | 0        |
    | 13 | Group B    |         | -2     | Class     | 0        |
    | 15 | gra-admin  |         | -2     | UserAdmin | 0        |
    | 14 | grayed     |         | -2     | Class     | 0        |
    | 16 | Group C    |         | -2     | Class     | 0        |
  And the database has the following table 'groups_groups':
    | ID | idGroupParent | idGroupChild | iVersion |
    | 61 | 13            | 11           | 0        |
    | 62 | 16            | 14           | 0        |
  And the database has the following table 'groups_ancestors':
    | ID | idGroupAncestor | idGroupChild | bIsSelf | iVersion |
    | 71 | 11              | 11           | 1       | 0        |
    | 72 | 12              | 12           | 1       | 0        |
    | 73 | 13              | 13           | 1       | 0        |
    | 74 | 13              | 11           | 0       | 0        |
    | 75 | 16              | 14           | 0       | 0        |
  And the database has the following table 'items':
    | ID  | sType    | bTeamsEditable | bNoScore | idItemUnlocked | bTransparentFolder | iVersion |
    | 190 | Category | false          | false    | 1234,2345      | true               | 0        |
    | 200 | Category | false          | false    | 1234,2345      | true               | 0        |
  And the database has the following table 'groups_items':
    | ID | idGroup | idItem | sFullAccessDate | bCachedFullAccess | bCachedPartialAccess | bCachedGrayedAccess | idUserCreated | iVersion |
    | 42 | 13      | 190    | null            | false             | false                | false               | 0             | 0        |
    | 43 | 13      | 200    | null            | true              | true                 | true                | 0             | 0        |
    | 44 | 16      | 190    | null            | false             | false                | true                | 0             | 0        |
    | 45 | 16      | 200    | null            | true              | true                 | true                | 0             | 0        |
  And the database has the following table 'items_strings':
    | ID | idItem | idLanguage | sTitle     | iVersion |
    | 53 | 200    | 1          | Category 1 | 0        |
  And the database has the following table 'users_items':
    | ID | idUser | idItem | iScore | nbSubmissionsAttempts | bValidated  | bFinished | bKeyObtained | sStartDate           | sFinishDate          | sValidationDate      | iVersion |
    | 1  | 1      | 200    | 12345  | 10                    | true        | true      | true         | 2019-01-30T09:26:41Z | 2019-02-01T09:26:41Z | 2019-01-31T09:26:41Z | 0        |

  Scenario: Should fail when the user doesn't have access to the root item
    Given I am the user with ID "1"
    When I send a GET request to "/items/190"
    Then the response code should be 404
    And the response error message should contain "Insufficient access rights on the given item id"

  Scenario: Should fail when the user doesn't have access to the root item (for a user with a non-existent group)
    Given I am the user with ID "2"
    When I send a GET request to "/items/200"
    Then the response code should be 404
    And the response error message should contain "Insufficient access rights on the given item id"

  Scenario: Should fail when the root item doesn't exist
    Given I am the user with ID "1"
    When I send a GET request to "/items/404"
    Then the response code should be 404
    And the response error message should contain "Insufficient access rights on the given item id"

  Scenario: Should fail when the user has only grayed access rights to the root item
    Given I am the user with ID "3"
    When I send a GET request to "/items/190"
    Then the response code should be 403
    And the response error message should contain "The item is grayed"

