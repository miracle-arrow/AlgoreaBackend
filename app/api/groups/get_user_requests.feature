Feature: Get pending requests for managed groups
  Background:
    Given the database has the following users:
      | login   | temp_user | group_id | first_name  | last_name | grade |
      | owner   | 0         | 21       | Jean-Michel | Blanquer  | 3     |
      | user    | 0         | 11       | John        | Doe       | 1     |
      | jane    | 0         | 31       | Jane        | Doe       | 2     |
      | richard | 0         | 41       | Richard     | Roe       | 2     |
    And the database has the following table 'groups':
      | id  | name       |
      | 1   | Root       |
      | 13  | Class      |
      | 14  | Friends    |
      | 22  | Group      |
      | 111 | Subgroup 1 |
      | 121 | Subgroup 2 |
      | 122 | Subgroup 3 |
      | 123 | Subgroup 4 |
      | 124 | Subgroup 5 |
      | 131 | Subgroup 6 |
    And the database has the following table 'group_managers':
      | group_id | manager_id | can_manage  |
      | 1        | 21         | memberships |
      | 13       | 21         | memberships |
      | 13       | 31         | none        |
      | 14       | 31         | memberships |
    And the database has the following table 'groups_groups':
      | parent_group_id | child_group_id |
      | 1               | 13             |
      | 1               | 14             |
      | 13              | 21             |
      | 13              | 11             |
      | 13              | 31             |
      | 13              | 22             |
      | 14              | 11             |
      | 14              | 31             |
      | 14              | 21             |
      | 14              | 22             |
      | 13              | 121            |
      | 13              | 111            |
      | 13              | 131            |
      | 13              | 122            |
      | 13              | 123            |
      | 13              | 124            |
    And the groups ancestors are computed
    And the database has the following table 'group_pending_requests':
      | group_id | member_id | type          | at                        |
      | 13       | 21        | invitation    | {{relativeTime("-170h")}} |
      | 13       | 31        | join_request  | {{relativeTime("-168h")}} |
      | 13       | 41        | join_request  | {{relativeTime("-169h")}} |
      | 13       | 11        | leave_request | {{relativeTime("-171h")}} |
      | 14       | 11        | invitation    | 2017-05-28 06:38:38       |
      | 14       | 21        | join_request  | 2017-05-27 06:38:38       |
      | 14       | 31        | leave_request | 2017-05-27 06:38:38       |

  Scenario: group_id is given (default sort)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=13"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      }
    ]
    """

  Scenario: group_id is given, include descendant groups (default sort)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=1&include_descendant_groups=1"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      },
      {
        "at": "2017-05-27T06:38:38Z",
        "group": {
          "id": "14",
          "name": "Friends"
        },
        "user": {
          "first_name": "Jean-Michel",
          "grade": 3,
          "group_id": "21",
          "last_name": "Blanquer",
          "login": "owner"
        }
      }
    ]
    """

  Scenario: group_id is given, include descendant groups (sort by group name desc & login)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=1&include_descendant_groups=1&sort=-group.name,user.login"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "at": "2017-05-27T06:38:38Z",
        "group": {
          "id": "14",
          "name": "Friends"
        },
        "user": {
          "first_name": "Jean-Michel",
          "grade": 3,
          "group_id": "21",
          "last_name": "Blanquer",
          "login": "owner"
        }
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      }
    ]
    """

  Scenario: group_id is given (sort by joining user's login)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=13&sort=user.login,user.group_id"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      }
    ]
    """

  Scenario: group_id is given, include descendant groups (sort by joining user's login desc)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=1&include_descendant_groups=1&sort=-user.login,user.group_id"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      },
      {
        "at": "2017-05-27T06:38:38Z",
        "group": {
          "id": "14",
          "name": "Friends"
        },
        "user": {
          "first_name": "Jean-Michel",
          "grade": 3,
          "group_id": "21",
          "last_name": "Blanquer",
          "login": "owner"
        }
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      }
    ]
    """

  Scenario: group_id is given; request the first row
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=13&limit=1"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      }
    ]
    """

  Scenario: group_id is given, include descendant groups (sort by group name desc & login, start from the second row)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=1&include_descendant_groups=1&sort=-group.name,user.login&from.group.name=Friends&from.user.login=owner&from.group.id=14&from.user.group_id=21"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      }
    ]
    """

  Scenario: group_id is not given (sort by group name desc & login)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?sort=-group.name,user.login"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "at": "2017-05-27T06:38:38Z",
        "group": {
          "id": "14",
          "name": "Friends"
        },
        "user": {
          "first_name": "Jean-Michel",
          "grade": 3,
          "group_id": "21",
          "last_name": "Blanquer",
          "login": "owner"
        }
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      }
    ]
    """

  Scenario: group_id is not given (sort by group name desc & login, start from the second row)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?sort=-group.name,user.login&from.group.name=Friends&from.user.login=owner&from.group.id=14&from.user.group_id=21"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      }
    ]
    """

  Scenario: group_id is not given, another user (sort by group name desc & login)
    Given I am the user with id "31"
    When I send a GET request to "/groups/user-requests?sort=-group.name,user.login"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "at": "2017-05-27T06:38:38Z",
        "group": {
          "id": "14",
          "name": "Friends"
        },
        "user": {
          "first_name": "Jean-Michel",
          "grade": 3,
          "group_id": "21",
          "last_name": "Blanquer",
          "login": "owner"
        }
      }
    ]
    """

  Scenario: group_id is given, types=leave_request (default sort)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=13&types=leave_request"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "John",
          "grade": 1,
          "group_id": "11",
          "last_name": "Doe",
          "login": "user"
        },
        "at": "{{timeToRFC(db("group_pending_requests[4][at]"))}}"
      }
    ]
    """

  Scenario: group_id is given, types=leave_request,join_request (default sort)
    Given I am the user with id "21"
    When I send a GET request to "/groups/user-requests?group_id=13&types=leave_request,join_request"
    Then the response code should be 200
    And the response body should be, in JSON:
    """
    [
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Jane",
          "grade": 2,
          "group_id": "31",
          "last_name": "Doe",
          "login": "jane"
        },
        "at": "{{timeToRFC(db("group_pending_requests[2][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "Richard",
          "grade": 2,
          "group_id": "41",
          "last_name": "Roe",
          "login": "richard"
        },
        "at": "{{timeToRFC(db("group_pending_requests[3][at]"))}}"
      },
      {
        "group": {
          "id": "13",
          "name": "Class"
        },
        "user": {
          "first_name": "John",
          "grade": 1,
          "group_id": "11",
          "last_name": "Doe",
          "login": "user"
        },
        "at": "{{timeToRFC(db("group_pending_requests[4][at]"))}}"
      }
    ]
    """