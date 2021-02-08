Feature: Create an access token
  Background:
    Given the database has the following table 'groups':
      | id | type | name      | created_at          |
      | 2  | Base | AllUsers  | 2015-08-10 12:34:55 |
    And the application config is:
      """
      auth:
        loginModuleURL: "https://login.algorea.org"
        clientID: "1"
        clientSecret: "tzxsLyFtJiGnmD6sjZMqSEidVpVsL3hEoSxIXCpI"
      domains:
        -
          domains: [127.0.0.1]
          allUsersGroup: 2
      """

  Scenario Outline: Create a new user
    Given the time now is "2019-07-16T22:02:28Z"
    And the DB time now is "2019-07-16 22:02:28"
    And the template constant "code_from_oauth" is "somecode"
    And the template constant "access_token_from_oauth" is "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijc3M2IyMjY0ZDU0MDUzNWQ5OTFlMjNlODY0MzljNzJmYjI0MWI5ZWY1ZTI5NjMyYjc3OWQwNjdlNmJmZWRiYmUyZDM4NmQ4YmQ2OTBlNGI3In0.eyJhdWQiOiIxIiwianRpIjoiNzczYjIyNjRkNTQwNTM1ZDk5MWUyM2U4NjQzOWM3MmZiMjQxYjllZjVlMjk2MzJiNzc5ZDA2N2U2YmZlZGJiZTJkMzg2ZDhiZDY5MGU0YjciLCJpYXQiOjE1NjM1Mjk4MjUsIm5iZiI6MTU2MzUyOTgyNSwiZXhwIjoxNTk1MTUyMjI0LCJzdWIiOiIxMDAwMDAwMDEiLCJzY29wZXMiOlsiYWNjb3VudCJdfQ.hcMLfoK8ocb0dpJg-R6EViMePCE4uw_Zzid_CIzFMFT6khY7m1kLorzKgYLWbDBxyxG-RBWTjJIbE-0J96VvLegYoZo5JObHzZP_FQyOUQ-qVe98mjI3Mc0a-dmr5bQyPTS2OC2COlFnletMHhBe4D_DSh2Zi8TfN79kTjsYErN59Vc4Bz0sPPmnLRqdKbg8r6jVX-s6cidN8mgDjujAljiaPkjCCiumdMj9kSfTKLNxMu1e9-4GfN41xc72ikstcBXjvakTyeq2-M9Wcby4XA5fys313kKlKQy3WJAVW3D6qMEwRH566vesEIx-RWUIlkPyV4QvIaE3k4mKdiO6c21LSFFSlIfr6jkVaGDvi8Rc9g77CWgUXaZOsETliW0Yea0tL9fG1negRr9uQGKyOZCM1dxSlBJAKlD3kyLi4ykEw6uTp0tM-AdwRB7mUpu9bw3evpr7f0mN65Nhd-byAuys0PXyegZeSKxZB3i1mAzE6s7vUbADJcBOx0kRmfkpT3kfUkJ4c9QohVCpkIMl80sbxcv9RTck0P9W1J-LGUULTtcPeaLNz85q7DKKbdiTAcbqzQkxZn0hO2wrF-3L0p_ms-yQg8ebu-ZJIzUG5LQq6Szu-QpXyQPP3NdKqHEvMhKoFY-9BZwA9SCEfiB8kMwCm9TAfztZBiCRcS2I4LE"
    And the template constant "refresh_token_from_oauth" is "def502008be6565fe7888139650994031dcf475fd4ec863d9d088562aeff095c4fb5026d189b05385b5d6e834bb26ed98d67b19f21c8e4f70e035083b8aba36027c748eb0a8fc987b900a96734eb3952733d8d87368cbf5194195dfee364ebe774117dc8e51075ea7afe356d985021a38be505ea7328137d0f3552dcf4ed1b7187affee3399964b81d396a597fb9ef78c1651c5203529cd016a9c9584fc024e597e47327c36431981000741c8e6e24066718b3b46d6278a0f13b0d1bd87e2811269a2464b832b765f45d40a878ce4d3bc9da03aad32dc6f17caa52f67befffd89bae734ac0b424d9a32bd2e47c47dfee43e534d36d6cc180759b3d220ddea18ba70d8490501934e960a9ad99012184fcd67f471a16c65db5185f24ace83857efefdd935280cc0a9653150d89f9ca531283ec9e566592de626d0c350ddd682f59ede69f29acfb0bc3104d826afabd0f1e1a246375154c78a9ad27a2c47bde5159686a4264bd91f16ffa185554d09858402a68"
    And the login module "token" endpoint for code "{{code_from_oauth}}" and code_verifier "123456" and redirect_uri "http://my.url" returns 200 with body:
      """
      {
        "token_type":"Bearer",
        "expires_in":31622400,
        "access_token":"{{access_token_from_oauth}}",
        "refresh_token":"{{refresh_token_from_oauth}}"
      }
      """
    And the login module "account" endpoint for token "{{access_token_from_oauth}}" returns 200 with body:
      """
      {
        "id":100000001, "login":"mohammed","login_updated_at":"2019-07-16 01:56:25","login_fixed":0,
        "login_revalidate_required":0,"login_change_required":0,"language":"en","first_name":"Mohammed",
        "last_name":"Amrani","real_name_visible":false,"timezone":"Africa\/Algiers","country_code":"DZ",
        "address":null,"city":null,"zipcode":null,"primary_phone":null,"secondary_phone":null,
        "role":"student","school_grade":null,"student_id":"123456789","ministry_of_education":null,
        "ministry_of_education_fr":false,"birthday":"2000-07-02","presentation":"I'm Mohammed Amrani",
        "website":"http://mohammed.freepages.com","ip":"127.0.0.1","picture":"http:\/\/127.0.0.1:8000\/images\/user.png",
        "gender":"m","graduation_year":2020,"graduation_grade_expire_at":"2020-07-01 00:00:00",
        "graduation_grade":0,"created_at":"2019-07-16 01:56:25","last_login":"2019-07-22 14:47:18",
        "logout_config":null,"last_password_recovery_at":null,"merge_group_id":null,
        "origin_instance_id":null,"creator_client_id":null,"nationality":"AL",
        "primary_email":"mohammedam@gmail.com","secondary_email":"mohammed.amrani@gmail.com",
        "primary_email_verified":null,"secondary_email_verified":null,"has_picture":false,
        "badges":[],"client_id":1,"verification":[]
      }
      """
    When I send a POST request to "/auth/token?code={{code_from_oauth}}&code_verifier=123456&redirect_uri=http%3A%2F%2Fmy.url<query>"
    Then the response code should be 201
    And the response body should be, in JSON:
      """
      {
        "success": true,
        "message": "created",
        "data": {
          <token_in_data>
          "expires_in": 31622400
        }
      }
      """
    And the response header "Set-Cookie" should be "<expected_cookie>"
    And the table "users" should be:
      | group_id            | latest_login_at     | latest_activity_at  | temp_user | registered_at       | login_id  | login    | email                | first_name | last_name | student_id | country_code | birth_date | graduation_year | grade | address | zipcode | city | land_line_number | cell_phone_number | default_language | free_text           | web_site                      | sex  | email_verified | last_ip   |
      | 5577006791947779410 | 2019-07-16 22:02:28 | 2019-07-16 22:02:28 | 0         | 2019-07-16 22:02:28 | 100000001 | mohammed | mohammedam@gmail.com | Mohammed   | Amrani    | 123456789  | dz           | 2000-07-02 | 2020            | 0     | null    | null    | null | null             | null              | en               | I'm Mohammed Amrani | http://mohammed.freepages.com | Male | 0              | 127.0.0.1 |
    And the table "groups" should be:
      | id                  | name     | type | description | created_at          | is_open | send_emails |
      | 2                   | AllUsers | Base | null        | 2015-08-10 12:34:55 | false   | false       |
      | 5577006791947779410 | mohammed | User | mohammed    | 2019-07-16 22:02:28 | false   | false       |
    And the table "groups_groups" should be:
      | parent_group_id | child_group_id      |
      | 2               | 5577006791947779410 |
    And the table "groups_ancestors" should be:
      | ancestor_group_id   | child_group_id      | is_self |
      | 2                   | 2                   | true    |
      | 2                   | 5577006791947779410 | false   |
      | 5577006791947779410 | 5577006791947779410 | true    |
    And the table "attempts" should be:
      | participant_id      | id | creator_id          | ABS(TIMESTAMPDIFF(SECOND, NOW(), created_at)) < 3 | parent_attempt_id | root_item_id |
      | 5577006791947779410 | 0  | 5577006791947779410 | true                                              | null              | null         |
    And the table "group_membership_changes" should be empty
    And the table "sessions" should be:
      | expires_at          | user_id             | issuer       | issued_at           | access_token                | use_cookie   | cookie_secure   | cookie_same_site   | cookie_domain   | cookie_path   |
      | 2020-07-16 22:02:28 | 5577006791947779410 | login-module | 2019-07-16 22:02:28 | {{access_token_from_oauth}} | <use_cookie> | <cookie_secure> | <cookie_same_site> | <cookie_domain> | <cookie_path> |
    And the table "refresh_tokens" should be:
      | user_id             | refresh_token                |
      | 5577006791947779410 | {{refresh_token_from_oauth}} |
  Examples:
    | query                            | token_in_data                                  | expected_cookie                                                                                                                                              | use_cookie | cookie_secure | cookie_same_site | cookie_domain | cookie_path |
    |                                  | "access_token": "{{access_token_from_oauth}}", | [NULL]                                                                                                                                                       | false      | false         | false            | null          | null        |
    | &use_cookie=1&cookie_secure=1    |                                                | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:28 GMT; Max-Age=31622400; HttpOnly; Secure; SameSite=None | true       | true          | false            | 127.0.0.1     | /           |
    | &use_cookie=1&cookie_same_site=1 |                                                | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:28 GMT; Max-Age=31622400; HttpOnly; SameSite=Strict       | true       | false         | true             | 127.0.0.1     | /           |

  Scenario Outline: Update an existing user
    Given the time now is "2019-07-16T22:02:28Z"
    And the DB time now is "2019-07-16 22:02:28"
    And the template constant "code_from_oauth" is "someanothercode"
    And the template constant "access_token_from_oauth" is "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImU3ODI4N2I2MjhhMjhlYmQ0NGU3ZDYwMGI3YzQ2MmQzMzFiZWUyZjg2ZWE2NGQ4MzNiOTBhMjJkYTNkYThmZjRlYzMyYTFiN2EyNDA2MWZmIn0.eyJhdWQiOiIxIiwianRpIjoiZTc4Mjg3YjYyOGEyOGViZDQ0ZTdkNjAwYjdjNDYyZDMzMWJlZTJmODZlYTY0ZDgzM2I5MGEyMmRhM2RhOGZmNGVjMzJhMWI3YTI0MDYxZmYiLCJpYXQiOjE1NjM4NDg4MjIsIm5iZiI6MTU2Mzg0ODgyMiwiZXhwIjoxNTk1NDcxMjIyLCJzdWIiOiIxMDAwMDAwMDEiLCJzY29wZXMiOlsiYWNjb3VudCJdfQ.W6aP5IdCRTGGlNp8IK-YF4lzoKD07ilv4xhNoNjyVdJkGic8eP4lnTE4s1NSvNxsrXkiYvwt78QAbQL6uCTqhdI-NHxDYOW-2EWUFYwRZxuLXqYuNkZD7iq9bN6kwLaZEUy-YpBIegC1bHUtKrUAHtS_4ZulNsJaN57V6M_W0VtiYDdox9OXzfAswWtHgedx6lNo-WfRhxfLf8gkWVHd6pRzYcKTWB3eeEy_lxNdw_v78IOM1WcdClp59pZT5C66OtQPhpOkHe33hMZgPuiVq887pwbIN3eaqXbX0D1CiELy_3NXMGFQoMBY8JHkch-2yJmOS-nA0vlUOpj4ddjfW8Rt15Yjq6Nuwy0okvzy5hlcK5vHnx9ORyyW9iEF2IK8Nt07nBrk-9scIhNLverdyL62gKJdrWvcn1gEHbCdY3A-0WPYhZ6sjH1NG2wmIcctjHe3ZCaP9JmEtdKH9RGQ5tnxoaA9H0ouJiXBrcc5uZ5h4nQqwZ5Cwf6--inkMe9kGmlq5AgqWZqpXpY11I9XInK6zjBngn2fEwgg0nRz72RK1i3s65YO8p7MiDTSE1_dMy72OQrA943HvrPd51SoJUmPI_VprG6Ayekyl_CJzIhF4vCyH6uWl8K4l83xxx6lXiVxfv0gl4bdQLBKlpku55rzMCNt34bHZHvH4vL4qzk"
    And the template constant "refresh_token_from_oauth" is "def502004ce3901576b99f1db359f8a5d2192336218515e7ca08fd2b923df4eb87c163d1660997f90cc16f4da734b9cb1ebff982574e4bc85c7d2de97cf4712dee42b7b729732c62d957a2e3c74d5b306d5b23bdf7be64074988a8f95e629709101a7f62f1ee36c3ece2e4ddf2f83ada76048276a3317ac6773a79968f1bc9ab5f16cb561e7547210a3bca354bfa36228da67dada8f68b5ad3d0d98b54222b18fdd46ad5ef47ce29cecbba63c6611604e8338dadeaa27de719fbe8479ffe49d8831d78ee825b37521215997ba139ae0d39534dc543f9d31e67a50dd03cd1c46fbf0990bcf89921307c4c85dd94c28158a5e28f3fd88d12b581d7da6aa2615930844329579c18ef1c1390cd17b1baf7236d82c59e80cbc7e68ed6c0ae35cabce1bfeb9ea29b50cd087ed1caadca5cad8f680d1c9ce5296da2da40479849d66b6ef31e1f2bc4f9bb094d288d331e94fe1e4e52526145b0f03a2a7b1c7743cd99ae79e2abaf2b92b87081bc014fcc65304cb1cb"
    And the template constant "profile_with_all_fields_set" is:
      """
      {
        "id":100000001, "login":"jane","login_updated_at":"2019-07-16 01:56:25","login_fixed":0,
        "login_revalidate_required":0,"login_change_required":0,"language":"en","first_name":"Jane",
        "last_name":"Doe","real_name_visible":false,"timezone":"Europe\/London","country_code":"GB",
        "address":null,"city":null,"zipcode":null,"primary_phone":null,"secondary_phone":null,
        "role":"student","school_grade":null,"student_id":"456789012","ministry_of_education":null,
        "ministry_of_education_fr":false,"birthday":"2001-08-03","presentation":"I'm Jane Doe",
        "website":"http://jane.freepages.com","ip":"192.168.11.1","picture":"http:\/\/127.0.0.1:8000\/images\/user.png",
        "gender":"f","graduation_year":2021,"graduation_grade_expire_at":"2020-07-01 00:00:00",
        "graduation_grade":0,"created_at":"2019-07-16 01:56:25","last_login":"2019-07-22 14:47:18",
        "logout_config":null,"last_password_recovery_at":null,"merge_group_id":null,
        "origin_instance_id":null,"creator_client_id":null,"nationality":"GB",
        "primary_email":"janedoe@gmail.com","secondary_email":"jane.doe@gmail.com",
        "primary_email_verified":1,"secondary_email_verified":null,"has_picture":false,
        "badges":[],"client_id":1,"verification":[]
      }
      """
    And the template constant "profile_with_null_fields" is:
      """
      {
        "id":100000001, "login":"jane","login_updated_at":null,"login_fixed":0,
        "login_revalidate_required":0,"login_change_required":0,"language":null,"first_name":null,
        "last_name":null,"real_name_visible":false,"timezone":null,"country_code":null,
        "address":null,"city":null,"zipcode":null,"primary_phone":null,"secondary_phone":null,
        "role":null,"school_grade":null,"student_id":null,"ministry_of_education":null,
        "ministry_of_education_fr":false,"birthday":null,"presentation":null,
        "website":null,"ip":null,"picture":null,
        "gender":null,"graduation_year":null,"graduation_grade_expire_at":null,
        "graduation_grade":null,"created_at":null,"last_login":null,
        "logout_config":null,"last_password_recovery_at":null,"merge_group_id":null,
        "origin_instance_id":null,"creator_client_id":null,"nationality":null,
        "primary_email":null,"secondary_email":null,
        "primary_email_verified":null,"secondary_email_verified":null,"has_picture":false,
        "badges":null,"client_id":null,"verification":null
      }
      """
    And the database table 'groups' has also the following rows:
      | id | name     | type | description | created_at          | is_open | send_emails |
      | 11 | mohammed | User | mohammed    | 2019-05-10 10:42:11 | false   | true        |
      | 13 | john     | User | john        | 2018-05-10 10:42:11 | false   | false       |
    And the database has the following table 'users':
      | group_id | latest_login_at     | latest_activity_at  | registered_at       | login_id  | login    | email                | first_name | last_name | student_id | country_code | birth_date | graduation_year | grade | address           | zipcode  | city                | land_line_number  | cell_phone_number | default_language | free_text           | web_site                      | sex  | email_verified | last_ip     |
      | 11       | 2019-06-16 21:01:25 | 2019-06-16 22:05:44 | 2019-05-10 10:42:11 | 100000001 | mohammed | mohammedam@gmail.com | Mohammed   | Amrani    | 123456789  | dz           | 2000-07-02 | 2020            | 0     | Rue Tebessi Larbi | 16000    | Algiers             | +213 778 02 85 31 | null              | en               | I'm Mohammed Amrani | http://mohammed.freepages.com | Male | 0              | 192.168.0.1 |
      | 13       | 2018-06-16 21:01:25 | 2018-06-16 22:05:44 | 2018-05-10 10:42:11 | 100000002 | john     | johndoe@gmail.com    | John       | Doe       | 987654321  | gb           | 1999-03-20 | 2021            | 1     | 1, Trafalgar sq.  | WC2N 5DN | City of Westminster | +44 20 7747 2885  | +44 333 300 7774  | en               | I'm John Doe        | http://johndoe.freepages.com  | Male | 1              | 110.55.10.2 |
    And the database has the following table 'groups_groups':
      | parent_group_id | child_group_id |
      | 2               | 11             |
      | 2               | 13             |
    And the groups ancestors are computed
    And the database has the following table 'sessions':
      | expires_at          | user_id | issuer       | issued_at           | access_token         | use_cookie | cookie_secure | cookie_same_site | cookie_domain | cookie_path |
      | 2020-06-16 22:02:49 | 11      | login-module | 2019-06-16 22:02:28 | previousaccesstoken1 | false      | false         | false            | null          | null        |
      | 2020-06-16 22:02:49 | 13      | login-module | 2019-06-16 22:02:28 | previousaccesstoken2 | false      | false         | false            | null          | null        |
    And the database has the following table 'refresh_tokens':
      | user_id | refresh_token         |
      | 11      | previousrefreshtoken1 |
      | 13      | previousrefreshtoken2 |
    And the login module "token" endpoint for code "{{code_from_oauth}}" returns 200 with body:
      """
      {
        "token_type":"Bearer",
        "expires_in":31622420,
        "access_token":"{{access_token_from_oauth}}",
        "refresh_token":"{{refresh_token_from_oauth}}"
      }
      """
    And the login module "account" endpoint for token "{{access_token_from_oauth}}" returns 200 with body:
      """
      {{<profile_response_name>}}
      """
    When I send a POST request to "/auth/token?code={{code_from_oauth}}"
    Then the response code should be 201
    And the response body should be, in JSON:
      """
      {
        "success": true,
        "message": "created",
        "data": {
          "access_token": "{{access_token_from_oauth}}",
          "expires_in": 31622420
        }
      }
      """
    And the response header "Set-Cookie" should be "[NULL]"
    And the table "users" should stay unchanged but the row with group_id "11"
    And the table "users" at group_id "11" should be:
      | group_id | latest_login_at     | latest_activity_at  | temp_user | registered_at       | login_id  | login | email   | first_name   | last_name   | student_id   | country_code   | birth_date   | graduation_year   | grade   | address | zipcode | city | land_line_number | cell_phone_number | default_language   | free_text   | web_site   | sex   | email_verified   | last_ip   |
      | 11       | 2019-07-16 22:02:28 | 2019-07-16 22:02:28 | 0         | 2019-05-10 10:42:11 | 100000001 | jane  | <email> | <first_name> | <last_name> | <student_id> | <country_code> | <birth_date> | <graduation_year> | <grade> | null    | null    | null | null             | null              | <default_language> | <free_text> | <web_site> | <sex> | <email_verified> | 127.0.0.1 |
    And the table "groups" should stay unchanged
    And the table "groups_groups" should stay unchanged
    And the table "groups_ancestors" should stay unchanged
    And the table "group_membership_changes" should be empty
    And the table "attempts" should stay unchanged
    And the table "sessions" should be:
      | expires_at          | user_id | issuer       | issued_at           | access_token                | use_cookie | cookie_secure | cookie_same_site | cookie_domain | cookie_path |
      | 2020-06-16 22:02:49 | 11      | login-module | 2019-06-16 22:02:28 | previousaccesstoken1        | false      | false         | false            | null          | null        |
      | 2020-06-16 22:02:49 | 13      | login-module | 2019-06-16 22:02:28 | previousaccesstoken2        | false      | false         | false            | null          | null        |
      | 2020-07-16 22:02:48 | 11      | login-module | 2019-07-16 22:02:28 | {{access_token_from_oauth}} | false      | false         | false            | null          | null        |
    And the table "refresh_tokens" should be:
      | user_id | refresh_token                |
      | 11      | {{refresh_token_from_oauth}} |
      | 13      | previousrefreshtoken2        |
  Examples:
    | profile_response_name       | email             | first_name | last_name | student_id | country_code | birth_date | graduation_year | grade | default_language | free_text    | web_site                  | sex    | email_verified |
    | profile_with_all_fields_set | janedoe@gmail.com | Jane       | Doe       | 456789012  | gb           | 2001-08-03 | 2021            | 0     | en               | I'm Jane Doe | http://jane.freepages.com | Female | true           |
    | profile_with_null_fields    | null              | null       | null      | null       |              | null       | 0               | null  | fr               | null         | null                      | null   | false          |

  Scenario: Creates relations with domain root groups on first login of an existing user
    Given the time now is "2019-07-16T22:02:29Z"
    And the DB time now is "2019-07-16 22:02:28"
    And the application config is:
      """
      auth:
        loginModuleURL: "https://login.algorea.org"
        clientID: "2"
        clientSecret: "tzxsLyFtJiGnmD6sjZMqSEidVpVsL3hEoSxIXCpI"
      """
    And the template constant "code_from_oauth" is "somecode"
    And the database table 'groups' has also the following rows:
      | id | name     | type | description | created_at          | is_open | send_emails |
      | 11 | mohammed | User | mohammed    | 2019-05-10 10:42:11 | false   | true        |
    And the database has the following table 'users':
      | group_id | latest_login_at     | latest_activity_at  | registered_at       | login_id  | login    | email                | first_name | last_name | student_id | country_code | birth_date | graduation_year | grade | address           | zipcode | city    | land_line_number  | cell_phone_number | default_language | free_text           | web_site                      | sex  | email_verified | last_ip     |
      | 11       | 2019-06-16 21:01:25 | 2019-06-16 22:05:44 | 2019-05-10 10:42:11 | 100000001 | mohammed | mohammedam@gmail.com | Mohammed   | Amrani    | 123456789  | dz           | 2000-07-02 | 2020            | 0     | Rue Tebessi Larbi | 16000   | Algiers | +213 778 02 85 31 | null              | en               | I'm Mohammed Amrani | http://mohammed.freepages.com | Male | 0              | 192.168.0.1 |
    And the groups ancestors are computed
    And the login module "token" endpoint for code "{{code_from_oauth}}" returns 200 with body:
      """
      {
        "token_type":"Bearer",
        "expires_in":31622420,
        "access_token":"accesstoken",
        "refresh_token":"refreshtoken"
      }
      """
    And the login module "account" endpoint for token "accesstoken" returns 200 with body:
      """
      {
        "id":100000001, "login":"mohammed","login_updated_at":"2019-07-16 01:56:25","login_fixed":0,
        "login_revalidate_required":0,"login_change_required":0,"language":"en","first_name":"Mohammed",
        "last_name":"Amrani","real_name_visible":false,"timezone":"Africa\/Algiers","country_code":"DZ",
        "address":null,"city":null,"zipcode":null,"primary_phone":null,"secondary_phone":null,
        "role":"student","school_grade":null,"student_id":"123456789","ministry_of_education":null,
        "ministry_of_education_fr":false,"birthday":"2000-07-02","presentation":"I'm Mohammed Amrani",
        "website":"http://mohammed.freepages.com","ip":"127.0.0.1","picture":"http:\/\/127.0.0.1:8000\/images\/user.png",
        "gender":"m","graduation_year":2020,"graduation_grade_expire_at":"2020-07-01 00:00:00",
        "graduation_grade":0,"created_at":"2019-07-16 01:56:25","last_login":"2019-07-22 14:47:18",
        "logout_config":null,"last_password_recovery_at":null,"merge_group_id":null,
        "origin_instance_id":null,"creator_client_id":null,"nationality":"AL",
        "primary_email":"mohammedam@gmail.com","secondary_email":"mohammed.amrani@gmail.com",
        "primary_email_verified":null,"secondary_email_verified":null,"has_picture":false,
        "badges":[],"client_id":1,"verification":[]
      }
      """
    When I send a POST request to "/auth/token?code={{code_from_oauth}}"
    Then the response code should be 201
    And the table "users" should stay unchanged but the row with group_id "11"
    And the table "users" at group_id "11" should be:
      | group_id |
      | 11       |
    And the table "groups" should stay unchanged
    And the table "groups_groups" should be:
      | parent_group_id | child_group_id |
      | 2               | 11             |
    And the table "groups_ancestors" should be:
      | ancestor_group_id | child_group_id | is_self |
      | 2                 | 2              | true    |
      | 2                 | 11             | false   |
      | 11                | 11             | true    |
    And the table "group_membership_changes" should be empty
    And the table "attempts" should stay unchanged

  Scenario Outline: Accepts parameters from POST data
    Given the time now is "2019-07-17T01:02:29+03:00"
    And the DB time now is "2019-07-16 22:02:28"
    And the template constant "code_from_oauth" is "somecode"
    And the template constant "access_token_from_oauth" is "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijc3M2IyMjY0ZDU0MDUzNWQ5OTFlMjNlODY0MzljNzJmYjI0MWI5ZWY1ZTI5NjMyYjc3OWQwNjdlNmJmZWRiYmUyZDM4NmQ4YmQ2OTBlNGI3In0.eyJhdWQiOiIxIiwianRpIjoiNzczYjIyNjRkNTQwNTM1ZDk5MWUyM2U4NjQzOWM3MmZiMjQxYjllZjVlMjk2MzJiNzc5ZDA2N2U2YmZlZGJiZTJkMzg2ZDhiZDY5MGU0YjciLCJpYXQiOjE1NjM1Mjk4MjUsIm5iZiI6MTU2MzUyOTgyNSwiZXhwIjoxNTk1MTUyMjI0LCJzdWIiOiIxMDAwMDAwMDEiLCJzY29wZXMiOlsiYWNjb3VudCJdfQ.hcMLfoK8ocb0dpJg-R6EViMePCE4uw_Zzid_CIzFMFT6khY7m1kLorzKgYLWbDBxyxG-RBWTjJIbE-0J96VvLegYoZo5JObHzZP_FQyOUQ-qVe98mjI3Mc0a-dmr5bQyPTS2OC2COlFnletMHhBe4D_DSh2Zi8TfN79kTjsYErN59Vc4Bz0sPPmnLRqdKbg8r6jVX-s6cidN8mgDjujAljiaPkjCCiumdMj9kSfTKLNxMu1e9-4GfN41xc72ikstcBXjvakTyeq2-M9Wcby4XA5fys313kKlKQy3WJAVW3D6qMEwRH566vesEIx-RWUIlkPyV4QvIaE3k4mKdiO6c21LSFFSlIfr6jkVaGDvi8Rc9g77CWgUXaZOsETliW0Yea0tL9fG1negRr9uQGKyOZCM1dxSlBJAKlD3kyLi4ykEw6uTp0tM-AdwRB7mUpu9bw3evpr7f0mN65Nhd-byAuys0PXyegZeSKxZB3i1mAzE6s7vUbADJcBOx0kRmfkpT3kfUkJ4c9QohVCpkIMl80sbxcv9RTck0P9W1J-LGUULTtcPeaLNz85q7DKKbdiTAcbqzQkxZn0hO2wrF-3L0p_ms-yQg8ebu-ZJIzUG5LQq6Szu-QpXyQPP3NdKqHEvMhKoFY-9BZwA9SCEfiB8kMwCm9TAfztZBiCRcS2I4LE"
    And the template constant "refresh_token_from_oauth" is "def502008be6565fe7888139650994031dcf475fd4ec863d9d088562aeff095c4fb5026d189b05385b5d6e834bb26ed98d67b19f21c8e4f70e035083b8aba36027c748eb0a8fc987b900a96734eb3952733d8d87368cbf5194195dfee364ebe774117dc8e51075ea7afe356d985021a38be505ea7328137d0f3552dcf4ed1b7187affee3399964b81d396a597fb9ef78c1651c5203529cd016a9c9584fc024e597e47327c36431981000741c8e6e24066718b3b46d6278a0f13b0d1bd87e2811269a2464b832b765f45d40a878ce4d3bc9da03aad32dc6f17caa52f67befffd89bae734ac0b424d9a32bd2e47c47dfee43e534d36d6cc180759b3d220ddea18ba70d8490501934e960a9ad99012184fcd67f471a16c65db5185f24ace83857efefdd935280cc0a9653150d89f9ca531283ec9e566592de626d0c350ddd682f59ede69f29acfb0bc3104d826afabd0f1e1a246375154c78a9ad27a2c47bde5159686a4264bd91f16ffa185554d09858402a68"
    And the login module "token" endpoint for code "{{code_from_oauth}}" and code_verifier "789012" and redirect_uri "http://my.url" returns 200 with body:
      """
      {
        "token_type":"Bearer",
        "expires_in":31622400,
        "access_token":"{{access_token_from_oauth}}",
        "refresh_token":"{{refresh_token_from_oauth}}"
      }
      """
    And the login module "account" endpoint for token "{{access_token_from_oauth}}" returns 200 with body:
      """
      {
        "id":100000001, "login":"mohammed","login_updated_at":"2019-07-16 01:56:25","login_fixed":0,
        "login_revalidate_required":0,"login_change_required":0,"language":"en","first_name":"Mohammed",
        "last_name":"Amrani","real_name_visible":false,"timezone":"Africa\/Algiers","country_code":"DZ",
        "address":null,"city":null,"zipcode":null,"primary_phone":null,"secondary_phone":null,
        "role":"student","school_grade":null,"student_id":"123456789","ministry_of_education":null,
        "ministry_of_education_fr":false,"birthday":"2000-07-02","presentation":"I'm Mohammed Amrani",
        "website":"http://mohammed.freepages.com","ip":"127.0.0.1","picture":"http:\/\/127.0.0.1:8000\/images\/user.png",
        "gender":"m","graduation_year":2020,"graduation_grade_expire_at":"2020-07-01 00:00:00",
        "graduation_grade":0,"created_at":"2019-07-16 01:56:25","last_login":"2019-07-22 14:47:18",
        "logout_config":null,"last_password_recovery_at":null,"merge_group_id":null,
        "origin_instance_id":null,"creator_client_id":null,"nationality":"AL",
        "primary_email":"mohammedam@gmail.com","secondary_email":"mohammed.amrani@gmail.com",
        "primary_email_verified":null,"secondary_email_verified":null,"has_picture":false,
        "badges":[],"client_id":1,"verification":[]
      }
      """
    And the "Content-Type" request header is "<content-type>"
    When I send a POST request to "/auth/token?code=wrong_code&code_verifier=123456" with the following body:
      """
      <data>
      """
    Then the response code should be 201
    And the response body should be, in JSON:
      """
      {
        "success": true,
        "message": "created",
        "data": {
          "access_token": "{{access_token_from_oauth}}",
          "expires_in": 31622400
        }
      }
      """
    And the response header "Set-Cookie" should be "[NULL]"
    And the table "sessions" should be:
      | user_id             | access_token                | use_cookie | cookie_secure | cookie_same_site | cookie_domain | cookie_path |
      | 5577006791947779410 | {{access_token_from_oauth}} | false      | false         | false            | null          | null        |
  Examples:
    | content-type                      | data                                                                        |
    | Application/x-www-form-urlencoded | code=somecode&code_verifier=789012&redirect_uri=http%3A%2F%2Fmy.url         |
    | application/jsoN; charset=utf8    | {"code":"somecode","code_verifier":"789012","redirect_uri":"http://my.url"} |

  Scenario Outline: Sets the cookie correctly when parameters are passed in the query for an existing user
    Given the time now is "2019-07-16T22:02:29Z"
    And the DB time now is "2019-07-16 22:02:28"
    And the template constant "code_from_oauth" is "someanothercode"
    And the template constant "access_token_from_oauth" is "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImU3ODI4N2I2MjhhMjhlYmQ0NGU3ZDYwMGI3YzQ2MmQzMzFiZWUyZjg2ZWE2NGQ4MzNiOTBhMjJkYTNkYThmZjRlYzMyYTFiN2EyNDA2MWZmIn0.eyJhdWQiOiIxIiwianRpIjoiZTc4Mjg3YjYyOGEyOGViZDQ0ZTdkNjAwYjdjNDYyZDMzMWJlZTJmODZlYTY0ZDgzM2I5MGEyMmRhM2RhOGZmNGVjMzJhMWI3YTI0MDYxZmYiLCJpYXQiOjE1NjM4NDg4MjIsIm5iZiI6MTU2Mzg0ODgyMiwiZXhwIjoxNTk1NDcxMjIyLCJzdWIiOiIxMDAwMDAwMDEiLCJzY29wZXMiOlsiYWNjb3VudCJdfQ.W6aP5IdCRTGGlNp8IK-YF4lzoKD07ilv4xhNoNjyVdJkGic8eP4lnTE4s1NSvNxsrXkiYvwt78QAbQL6uCTqhdI-NHxDYOW-2EWUFYwRZxuLXqYuNkZD7iq9bN6kwLaZEUy-YpBIegC1bHUtKrUAHtS_4ZulNsJaN57V6M_W0VtiYDdox9OXzfAswWtHgedx6lNo-WfRhxfLf8gkWVHd6pRzYcKTWB3eeEy_lxNdw_v78IOM1WcdClp59pZT5C66OtQPhpOkHe33hMZgPuiVq887pwbIN3eaqXbX0D1CiELy_3NXMGFQoMBY8JHkch-2yJmOS-nA0vlUOpj4ddjfW8Rt15Yjq6Nuwy0okvzy5hlcK5vHnx9ORyyW9iEF2IK8Nt07nBrk-9scIhNLverdyL62gKJdrWvcn1gEHbCdY3A-0WPYhZ6sjH1NG2wmIcctjHe3ZCaP9JmEtdKH9RGQ5tnxoaA9H0ouJiXBrcc5uZ5h4nQqwZ5Cwf6--inkMe9kGmlq5AgqWZqpXpY11I9XInK6zjBngn2fEwgg0nRz72RK1i3s65YO8p7MiDTSE1_dMy72OQrA943HvrPd51SoJUmPI_VprG6Ayekyl_CJzIhF4vCyH6uWl8K4l83xxx6lXiVxfv0gl4bdQLBKlpku55rzMCNt34bHZHvH4vL4qzk"
    And the template constant "refresh_token_from_oauth" is "def502004ce3901576b99f1db359f8a5d2192336218515e7ca08fd2b923df4eb87c163d1660997f90cc16f4da734b9cb1ebff982574e4bc85c7d2de97cf4712dee42b7b729732c62d957a2e3c74d5b306d5b23bdf7be64074988a8f95e629709101a7f62f1ee36c3ece2e4ddf2f83ada76048276a3317ac6773a79968f1bc9ab5f16cb561e7547210a3bca354bfa36228da67dada8f68b5ad3d0d98b54222b18fdd46ad5ef47ce29cecbba63c6611604e8338dadeaa27de719fbe8479ffe49d8831d78ee825b37521215997ba139ae0d39534dc543f9d31e67a50dd03cd1c46fbf0990bcf89921307c4c85dd94c28158a5e28f3fd88d12b581d7da6aa2615930844329579c18ef1c1390cd17b1baf7236d82c59e80cbc7e68ed6c0ae35cabce1bfeb9ea29b50cd087ed1caadca5cad8f680d1c9ce5296da2da40479849d66b6ef31e1f2bc4f9bb094d288d331e94fe1e4e52526145b0f03a2a7b1c7743cd99ae79e2abaf2b92b87081bc014fcc65304cb1cb"
    And the database table 'groups' has also the following rows:
      | id | name     | type | description | created_at          | is_open | send_emails |
      | 11 | mohammed | User | mohammed    | 2019-05-10 10:42:11 | false   | true        |
      | 13 | john     | User | john        | 2018-05-10 10:42:11 | false   | false       |
    And the database has the following table 'users':
      | group_id | latest_login_at     | latest_activity_at  | registered_at       | login_id  | login    | email                | first_name | last_name | student_id | country_code | birth_date | graduation_year | grade | address           | zipcode  | city                | land_line_number  | cell_phone_number | default_language | free_text           | web_site                      | sex  | email_verified | last_ip     |
      | 11       | 2019-06-16 21:01:25 | 2019-06-16 22:05:44 | 2019-05-10 10:42:11 | 100000001 | mohammed | mohammedam@gmail.com | Mohammed   | Amrani    | 123456789  | dz           | 2000-07-02 | 2020            | 0     | Rue Tebessi Larbi | 16000    | Algiers             | +213 778 02 85 31 | null              | en               | I'm Mohammed Amrani | http://mohammed.freepages.com | Male | 0              | 192.168.0.1 |
      | 13       | 2018-06-16 21:01:25 | 2018-06-16 22:05:44 | 2018-05-10 10:42:11 | 100000002 | john     | johndoe@gmail.com    | John       | Doe       | 987654321  | gb           | 1999-03-20 | 2021            | 1     | 1, Trafalgar sq.  | WC2N 5DN | City of Westminster | +44 20 7747 2885  | +44 333 300 7774  | en               | I'm John Doe        | http://johndoe.freepages.com  | Male | 1              | 110.55.10.2 |
    And the database has the following table 'groups_groups':
      | parent_group_id | child_group_id |
      | 2               | 11             |
      | 2               | 13             |
    And the groups ancestors are computed
    And the database has the following table 'sessions':
      | expires_at          | user_id | issuer       | issued_at           | access_token         | use_cookie | cookie_secure | cookie_same_site | cookie_domain | cookie_path |
      | 2020-06-16 22:02:49 | 11      | login-module | 2019-06-16 22:02:28 | previousaccesstoken1 | false      | false         | false            | null          | null        |
      | 2020-06-16 22:02:49 | 13      | login-module | 2019-06-16 22:02:28 | previousaccesstoken2 | false      | false         | false            | null          | null        |
    And the database has the following table 'refresh_tokens':
      | user_id | refresh_token         |
      | 11      | previousrefreshtoken1 |
      | 13      | previousrefreshtoken2 |
    And the login module "token" endpoint for code "{{code_from_oauth}}" returns 200 with body:
      """
      {
        "token_type":"Bearer",
        "expires_in":31622420,
        "access_token":"{{access_token_from_oauth}}",
        "refresh_token":"{{refresh_token_from_oauth}}"
      }
      """
    And the login module "account" endpoint for token "{{access_token_from_oauth}}" returns 200 with body:
      """
      {
        "id":100000001, "login":"jane","login_updated_at":"2019-07-16 01:56:25","login_fixed":0,
        "login_revalidate_required":0,"login_change_required":0,"language":"en","first_name":"Jane",
        "last_name":"Doe","real_name_visible":false,"timezone":"Europe\/London","country_code":"GB",
        "address":null,"city":null,"zipcode":null,"primary_phone":null,"secondary_phone":null,
        "role":"student","school_grade":null,"student_id":"456789012","ministry_of_education":null,
        "ministry_of_education_fr":false,"birthday":"2001-08-03","presentation":"I'm Jane Doe",
        "website":"http://jane.freepages.com","ip":"192.168.11.1","picture":"http:\/\/127.0.0.1:8000\/images\/user.png",
        "gender":"f","graduation_year":2021,"graduation_grade_expire_at":"2020-07-01 00:00:00",
        "graduation_grade":0,"created_at":"2019-07-16 01:56:25","last_login":"2019-07-22 14:47:18",
        "logout_config":null,"last_password_recovery_at":null,"merge_group_id":null,
        "origin_instance_id":null,"creator_client_id":null,"nationality":"GB",
        "primary_email":"janedoe@gmail.com","secondary_email":"jane.doe@gmail.com",
        "primary_email_verified":1,"secondary_email_verified":null,"has_picture":false,
        "badges":[],"client_id":1,"verification":[]
      }
      """
    When I send a POST request to "/auth/token<query>"
    Then the response code should be 201
    And the response body should be, in JSON:
      """
      {
        "success": true,
        "message": "created",
        "data": {
          "expires_in": 31622420
        }
      }
      """
    And the response header "Set-Cookie" should be "<expected_cookie>"
    And the table "sessions" should be:
      | user_id | access_token                | use_cookie | cookie_secure   | cookie_same_site   | cookie_domain | cookie_path |
      | 11      | {{access_token_from_oauth}} | true       | <cookie_secure> | <cookie_same_site> | 127.0.0.1     | /           |
      | 11      | previousaccesstoken1        | false      | false           | false              | null          | null        |
      | 13      | previousaccesstoken2        | false      | false           | false              | null          | null        |
    Examples:
      | query                                                     | expected_cookie                                                                                                                                              | cookie_secure | cookie_same_site |
      | ?code={{code_from_oauth}}&use_cookie=1&cookie_secure=1    | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:49 GMT; Max-Age=31622420; HttpOnly; Secure; SameSite=None | true          | false            |
      | ?code={{code_from_oauth}}&use_cookie=1&cookie_same_site=1 | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:49 GMT; Max-Age=31622420; HttpOnly; SameSite=Strict       | false         | true             |

  Scenario Outline: Accepts parameters from POST data and sets the cookie correctly
    Given the time now is "2019-07-17T01:02:29+03:00"
    And the DB time now is "2019-07-16 22:02:28"
    And the template constant "code_from_oauth" is "somecode"
    And the template constant "access_token_from_oauth" is "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6Ijc3M2IyMjY0ZDU0MDUzNWQ5OTFlMjNlODY0MzljNzJmYjI0MWI5ZWY1ZTI5NjMyYjc3OWQwNjdlNmJmZWRiYmUyZDM4NmQ4YmQ2OTBlNGI3In0.eyJhdWQiOiIxIiwianRpIjoiNzczYjIyNjRkNTQwNTM1ZDk5MWUyM2U4NjQzOWM3MmZiMjQxYjllZjVlMjk2MzJiNzc5ZDA2N2U2YmZlZGJiZTJkMzg2ZDhiZDY5MGU0YjciLCJpYXQiOjE1NjM1Mjk4MjUsIm5iZiI6MTU2MzUyOTgyNSwiZXhwIjoxNTk1MTUyMjI0LCJzdWIiOiIxMDAwMDAwMDEiLCJzY29wZXMiOlsiYWNjb3VudCJdfQ.hcMLfoK8ocb0dpJg-R6EViMePCE4uw_Zzid_CIzFMFT6khY7m1kLorzKgYLWbDBxyxG-RBWTjJIbE-0J96VvLegYoZo5JObHzZP_FQyOUQ-qVe98mjI3Mc0a-dmr5bQyPTS2OC2COlFnletMHhBe4D_DSh2Zi8TfN79kTjsYErN59Vc4Bz0sPPmnLRqdKbg8r6jVX-s6cidN8mgDjujAljiaPkjCCiumdMj9kSfTKLNxMu1e9-4GfN41xc72ikstcBXjvakTyeq2-M9Wcby4XA5fys313kKlKQy3WJAVW3D6qMEwRH566vesEIx-RWUIlkPyV4QvIaE3k4mKdiO6c21LSFFSlIfr6jkVaGDvi8Rc9g77CWgUXaZOsETliW0Yea0tL9fG1negRr9uQGKyOZCM1dxSlBJAKlD3kyLi4ykEw6uTp0tM-AdwRB7mUpu9bw3evpr7f0mN65Nhd-byAuys0PXyegZeSKxZB3i1mAzE6s7vUbADJcBOx0kRmfkpT3kfUkJ4c9QohVCpkIMl80sbxcv9RTck0P9W1J-LGUULTtcPeaLNz85q7DKKbdiTAcbqzQkxZn0hO2wrF-3L0p_ms-yQg8ebu-ZJIzUG5LQq6Szu-QpXyQPP3NdKqHEvMhKoFY-9BZwA9SCEfiB8kMwCm9TAfztZBiCRcS2I4LE"
    And the template constant "refresh_token_from_oauth" is "def502008be6565fe7888139650994031dcf475fd4ec863d9d088562aeff095c4fb5026d189b05385b5d6e834bb26ed98d67b19f21c8e4f70e035083b8aba36027c748eb0a8fc987b900a96734eb3952733d8d87368cbf5194195dfee364ebe774117dc8e51075ea7afe356d985021a38be505ea7328137d0f3552dcf4ed1b7187affee3399964b81d396a597fb9ef78c1651c5203529cd016a9c9584fc024e597e47327c36431981000741c8e6e24066718b3b46d6278a0f13b0d1bd87e2811269a2464b832b765f45d40a878ce4d3bc9da03aad32dc6f17caa52f67befffd89bae734ac0b424d9a32bd2e47c47dfee43e534d36d6cc180759b3d220ddea18ba70d8490501934e960a9ad99012184fcd67f471a16c65db5185f24ace83857efefdd935280cc0a9653150d89f9ca531283ec9e566592de626d0c350ddd682f59ede69f29acfb0bc3104d826afabd0f1e1a246375154c78a9ad27a2c47bde5159686a4264bd91f16ffa185554d09858402a68"
    And the login module "token" endpoint for code "{{code_from_oauth}}" and code_verifier "789012" and redirect_uri "http://my.url" returns 200 with body:
      """
      {
        "token_type":"Bearer",
        "expires_in":31622400,
        "access_token":"{{access_token_from_oauth}}",
        "refresh_token":"{{refresh_token_from_oauth}}"
      }
      """
    And the login module "account" endpoint for token "{{access_token_from_oauth}}" returns 200 with body:
      """
      {
        "id":100000001, "login":"mohammed","login_updated_at":"2019-07-16 01:56:25","login_fixed":0,
        "login_revalidate_required":0,"login_change_required":0,"language":"en","first_name":"Mohammed",
        "last_name":"Amrani","real_name_visible":false,"timezone":"Africa\/Algiers","country_code":"DZ",
        "address":null,"city":null,"zipcode":null,"primary_phone":null,"secondary_phone":null,
        "role":"student","school_grade":null,"student_id":"123456789","ministry_of_education":null,
        "ministry_of_education_fr":false,"birthday":"2000-07-02","presentation":"I'm Mohammed Amrani",
        "website":"http://mohammed.freepages.com","ip":"127.0.0.1","picture":"http:\/\/127.0.0.1:8000\/images\/user.png",
        "gender":"m","graduation_year":2020,"graduation_grade_expire_at":"2020-07-01 00:00:00",
        "graduation_grade":0,"created_at":"2019-07-16 01:56:25","last_login":"2019-07-22 14:47:18",
        "logout_config":null,"last_password_recovery_at":null,"merge_group_id":null,
        "origin_instance_id":null,"creator_client_id":null,"nationality":"AL",
        "primary_email":"mohammedam@gmail.com","secondary_email":"mohammed.amrani@gmail.com",
        "primary_email_verified":null,"secondary_email_verified":null,"has_picture":false,
        "badges":[],"client_id":1,"verification":[]
      }
      """
    And the "Content-Type" request header is "<content-type>"
    When I send a POST request to "/auth/token?code=wrong_code&code_verifier=123456" with the following body:
      """
      <data>
      """
    Then the response code should be 201
    And the response body should be, in JSON:
      """
      {
        "success": true,
        "message": "created",
        "data": {
          "expires_in": 31622400
        }
      }
      """
    And the response header "Set-Cookie" should be "<expected_cookie>"
    And the table "sessions" should be:
      | user_id             | access_token                | use_cookie | cookie_secure   | cookie_same_site   | cookie_domain | cookie_path |
      | 5577006791947779410 | {{access_token_from_oauth}} | true       | <cookie_secure> | <cookie_same_site> | 127.0.0.1     | /           |
    Examples:
      | content-type                      | data                                                                                                                                        | expected_cookie                                                                                                                                                | cookie_secure | cookie_same_site |
      | Application/x-www-form-urlencoded | code=somecode&code_verifier=789012&redirect_uri=http%3A%2F%2Fmy.url&use_cookie=1&cookie_secure=1                                            | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:29 GMT; Max-Age=31622400; HttpOnly; Secure; SameSite=None   | true          | false            |
      | Application/x-www-form-urlencoded | code=somecode&code_verifier=789012&redirect_uri=http%3A%2F%2Fmy.url&use_cookie=1&cookie_secure=1&cookie_same_site=1                         | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:29 GMT; Max-Age=31622400; HttpOnly; Secure; SameSite=Strict | true          | true             |
      | Application/x-www-form-urlencoded | code=somecode&code_verifier=789012&redirect_uri=http%3A%2F%2Fmy.url&use_cookie=1&cookie_secure=0&cookie_same_site=1                         | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:29 GMT; Max-Age=31622400; HttpOnly; SameSite=Strict         | false         | true             |
      | application/jsoN; charset=utf8    | {"code":"somecode","code_verifier":"789012","redirect_uri":"http://my.url","use_cookie":true,"cookie_secure":true}                          | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:29 GMT; Max-Age=31622400; HttpOnly; Secure; SameSite=None   | true          | false            |
      | application/json                  | {"code":"somecode","code_verifier":"789012","redirect_uri":"http://my.url","use_cookie":true,"cookie_secure":true,"cookie_same_site":true}  | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:29 GMT; Max-Age=31622400; HttpOnly; Secure; SameSite=Strict | true          | true             |
      | Application/json                  | {"code":"somecode","code_verifier":"789012","redirect_uri":"http://my.url","use_cookie":true,"cookie_secure":false,"cookie_same_site":true} | access_token={{access_token_from_oauth}}; Path=/; Domain=127.0.0.1; Expires=Thu, 16 Jul 2020 22:02:29 GMT; Max-Age=31622400; HttpOnly; SameSite=Strict         | false         | true             |
