Feature: Ask for a hint
  Background:
    Given the database has the following table 'users':
      | ID  | sLogin | idGroupSelf |
      | 10  | john   | 101         |
    And the database has the following table 'groups':
      | ID  |
      | 101 |
    And the database has the following table 'groups_ancestors':
      | idGroupAncestor | idGroupChild | bIsSelf |
      | 101             | 101          | 1       |
    And the database has the following table 'groups_groups':
      | ID | idGroupParent | idGroupChild | sType              | sStatusDate |
      | 15 | 22            | 13           | direct             | null        |
    And the database has the following table 'platforms':
      | ID | bUsesTokens | sRegexp                                           | sPublicKey                |
      | 10 | 1           | http://taskplatform.mblockelet.info/task.html\?.* | {{taskPlatformPublicKey}} |
    And the database has the following table 'items':
      | ID | idPlatform | sUrl                                                                    |
      | 50 | 10         | http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936 |
      | 10 | null       | null                                                                    |
    And the database has the following table 'items_items':
      | idItemParent | idItemChild |
      | 10           | 50          |
    And the database has the following table 'items_ancestors':
      | idItemAncestor | idItemChild |
      | 10             | 50          |
    And the database has the following table 'groups_items':
      | idGroup | idItem | sCachedPartialAccessDate |
      | 101     | 50     | 2017-05-29T06:38:38Z     |
    And the database has the following table 'users_items':
      | idUser | idItem | sHintsRequested    | nbHintsCached | nbSubmissionsAttempts | idAttemptActive |
      | 10     | 50     | [{"rotorIndex":0}] | 1             | 2                     | 100             |
      | 10     | 10     | null               | 0             | 0                     | null            |
    And time is frozen

  Scenario: User is able to ask for a hint
    Given I am the user with ID "10"
    And the database has the following table 'groups_attempts':
      | ID  | idGroup | idItem | sHintsRequested        | nbHintsCached |
      | 100 | 101     | 50     | [0,  1, "hint" , null] | 4             |
    And the following token "priorUserTaskToken" signed by the app is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemURL": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "platformName": "{{app().TokenConfig.PlatformName}}"
      }
      """
    And the following token "hintRequestToken" signed by the task platform is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemUrl": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "askedHint": {"rotorIndex":1}
      }
      """
    When I send a POST request to "/items/ask_hint" with the following body:
      """
      {
        "task_token": "{{priorUserTaskToken}}",
        "hint_requested": "{{hintRequestToken}}"
      }
      """
    Then the response code should be 201
    And the response body decoded as "AskHintResponse" should be, in JSON:
      """
      {
        "data": {
          "task_token": {
            "date": "{{currentTimeInFormat("02-01-2006")}}",
            "idUser": "10",
            "idItemLocal": "50",
            "idAttempt": "100",
            "itemUrl": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
            "randomSeed": "",
            "platformName": "{{app().TokenConfig.PlatformName}}",
            "sHintsRequested": "[0,1,\"hint\",null,{\"rotorIndex\":1}]",
            "nbHintsGiven": "5"
          }
        },
        "message": "created",
        "success": true
      }
      """
    And the table "users_items" should be:
      | idUser | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested    | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 10     | 10     | 1               | 0             | null               | done                       | 1                                  | null                           |
      | 10     | 50     | 1               | 1             | [{"rotorIndex":0}] | done                       | 1                                  | 1                              |
    And the table "groups_attempts" should be:
      | ID  | idGroup | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested                    | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 100 | 101     | 50     | 1               | 5             | [0,1,"hint",null,{"rotorIndex":1}] | done                       | 1                                  | 1                              |

  Scenario: User is able to ask for a hint with a minimal hint token
    Given I am the user with ID "10"
    And the database has the following table 'groups_attempts':
      | ID  | idGroup | idItem | sHintsRequested        |
      | 100 | 101     | 50     | [0,  1, "hint" , null] |
    And the following token "priorUserTaskToken" signed by the app is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemURL": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "platformName": "{{app().TokenConfig.PlatformName}}"
      }
      """
    And the following token "hintRequestToken" signed by the task platform is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemURL": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "askedHint": {"rotorIndex":1}
      }
      """
    When I send a POST request to "/items/ask_hint" with the following body:
      """
      {
        "task_token": "{{priorUserTaskToken}}",
        "hint_requested": "{{hintRequestToken}}"
      }
      """
    Then the response code should be 201
    And the response body decoded as "AskHintResponse" should be, in JSON:
      """
      {
        "data": {
          "task_token": {
            "date": "{{currentTimeInFormat("02-01-2006")}}",
            "idUser": "10",
            "idItemLocal": "50",
            "idAttempt": "100",
            "itemUrl": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
            "randomSeed": "",
            "platformName": "{{app().TokenConfig.PlatformName}}",
            "sHintsRequested": "[0,1,\"hint\",null,{\"rotorIndex\":1}]",
            "nbHintsGiven": "5"
          }
        },
        "message": "created",
        "success": true
      }
      """
    And the table "users_items" should be:
      | idUser | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested    | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 10     | 10     | 1               | 0             | null               | done                       | 1                                  | null                           |
      | 10     | 50     | 1               | 1             | [{"rotorIndex":0}] | done                       | 1                                  | 1                              |
    And the table "groups_attempts" should be:
      | ID  | idGroup | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested                    | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 100 | 101     | 50     | 1               | 5             | [0,1,"hint",null,{"rotorIndex":1}] | done                       | 1                                  | 1                              |

  Scenario: User is able to ask for an already given hint
    Given I am the user with ID "10"
    And the database has the following table 'groups_attempts':
      | ID  | idGroup | idItem | sHintsRequested        |
      | 100 | 101     | 50     | [0,  1, "hint" , null] |
    And the following token "priorUserTaskToken" signed by the app is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemURL": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "platformName": "{{app().TokenConfig.PlatformName}}"
      }
      """
    And the following token "hintRequestToken" signed by the task platform is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemUrl": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "askedHint": "hint"
      }
      """
    When I send a POST request to "/items/ask_hint" with the following body:
      """
      {
        "task_token": "{{priorUserTaskToken}}",
        "hint_requested": "{{hintRequestToken}}"
      }
      """
    Then the response code should be 201
    And the response body decoded as "AskHintResponse" should be, in JSON:
      """
      {
        "data": {
          "task_token": {
            "date": "{{currentTimeInFormat("02-01-2006")}}",
            "idUser": "10",
            "idItemLocal": "50",
            "idAttempt": "100",
            "itemUrl": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
            "randomSeed": "",
            "platformName": "{{app().TokenConfig.PlatformName}}",
            "sHintsRequested": "[0,1,\"hint\",null]",
            "nbHintsGiven": "4"
          }
        },
        "message": "created",
        "success": true
      }
      """
    And the table "users_items" should be:
      | idUser | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested    | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 10     | 10     | 1               | 0             | null               | done                       | 1                                  | null                           |
      | 10     | 50     | 1               | 1             | [{"rotorIndex":0}] | done                       | 1                                  | 1                              |
    And the table "groups_attempts" should be:
      | ID  | idGroup | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested   | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 100 | 101     | 50     | 1               | 4             | [0,1,"hint",null] | done                       | 1                                  | 1                              |

  Scenario: Can't parse sHintsRequested
    Given I am the user with ID "10"
    And the database has the following table 'groups_attempts':
      | ID  | idGroup | idItem | sHintsRequested        |
      | 100 | 101     | 50     | not an array           |
    And the following token "priorUserTaskToken" signed by the app is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemURL": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "platformName": "{{app().TokenConfig.PlatformName}}"
      }
      """
    And the following token "hintRequestToken" signed by the task platform is distributed:
      """
      {
        "idUser": "10",
        "idItemLocal": "50",
        "idAttempt": "100",
        "itemUrl": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
        "askedHint": {"rotorIndex":1}
      }
      """
    When I send a POST request to "/items/ask_hint" with the following body:
      """
      {
        "task_token": "{{priorUserTaskToken}}",
        "hint_requested": "{{hintRequestToken}}"
      }
      """
    Then the response code should be 201
    And the response body decoded as "AskHintResponse" should be, in JSON:
      """
      {
        "data": {
          "task_token": {
            "date": "{{currentTimeInFormat("02-01-2006")}}",
            "idUser": "10",
            "idItemLocal": "50",
            "idAttempt": "100",
            "itemUrl": "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
            "randomSeed": "",
            "platformName": "{{app().TokenConfig.PlatformName}}",
            "sHintsRequested": "[{\"rotorIndex\":1}]",
            "nbHintsGiven": "1"
          }
        },
        "message": "created",
        "success": true
      }
      """
    And the table "users_items" should be:
      | idUser | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested    | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 10     | 10     | 1               | 0             | null               | done                       | 1                                  | null                           |
      | 10     | 50     | 1               | 1             | [{"rotorIndex":0}] | done                       | 1                                  | 1                              |
    And the table "groups_attempts" should be:
      | ID  | idGroup | idItem | nbTasksWithHelp | nbHintsCached | sHintsRequested    | sAncestorsComputationState | ABS(sLastActivityDate - NOW()) < 3 | ABS(sLastHintDate - NOW()) < 3 |
      | 100 | 101     | 50     | 1               | 1             | [{"rotorIndex":1}] | done                       | 1                                  | 1                              |
    And logs should contain:
      """
      Unable to parse sHintsRequested ({"idAttempt":100,"idItem":50,"idUser":10}) having value "not an array": invalid character 'o' in literal null (expecting 'u')
      """
