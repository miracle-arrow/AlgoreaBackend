Feature: Add item

Background:
  Given the database has the following table 'users':
    | ID | sLogin | tempUser | idGroupSelf | iVersion |
    | 1  | jdoe   | 0        | 11          | 0        |
  And the database has the following table 'groups':
    | ID | sName      | sTextId | iGrade | sType     | iVersion |
    | 11 | jdoe       |         | -2     | UserAdmin | 0        |
  And the database has the following table 'items':
    | ID | bTeamsEditable | bNoScore | iVersion |
    | 21 | false          | false    | 0        |
  And the database has the following table 'groups_items':
    | ID | idGroup | idItem | bManagerAccess | idUserCreated | iVersion |
    | 41 | 11      | 21     | true           | 0             | 0        |

Scenario: Valid, id is given
When I send a POST request to "/items/" with the following body:
  """
  {
    "id": 2,
    "type": "Course",
    "strings": [
      { "language_id": 3, "title": "my title" }
    ],
    "parents": [
      { "id": 21, "order": 100 }
    ]
  }
  """
Then the response code should be 201
And the response body should be, in JSON:
"""
{
  "success": true,
  "message": "success",
  "data": { "ID": 2 }
}
"""
And the table "items" at ID "2" should be:
  | ID | sType  | sUrl |
  |  2 | Course | NULL |
And the table "items_strings" should be:
  |                  ID | idItem  | idLanguage |   sTitle |
  | 8674665223082153551 |      2  |          3 | my title |
And the table "items_items" should be:
  |                  ID | idItemParent | idItemChild | iChildOrder |
  | 6129484611666145821 |           21 |           2 |         100 |
And the table "groups_items" at ID "5577006791947779410" should be:
  |                  ID | idGroup | idItem |     sFullAccessDate | bCachedFullAccess | bOwnerAccess | idUserCreated |
  | 5577006791947779410 |       6 |      2 | 2018-01-01 00:00:00 |                 0 |            0 |             0 |

Scenario: Id not given
When I send a POST request to "/items/" with the following body:
  """
  {
    "type": "Course",
    "strings": [
      { "language_id": 3, "title": "my title" }
    ],
    "parents": [
      { "id": 4, "order": 100 }
    ]
  }
  """
Then the response code should be 201
And the table "items" at ID "5577006791947779410" should be:
  | sType  | sUrl |
  | Course | NULL |
