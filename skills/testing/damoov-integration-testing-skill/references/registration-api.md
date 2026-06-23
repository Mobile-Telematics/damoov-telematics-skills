# Registration API — Create User and User Login

---

## Create user

**Endpoint:** `POST https://user.telematicssdk.com/v1/Registration/create`

**Required headers:**
- `InstanceId` — from Datahub Hierarchy Management (see hierarchy.md)
- `InstanceKey` — from Datahub Hierarchy Management (see hierarchy.md)

**All body fields are optional.**

```bash
curl --request POST \
     --url https://user.telematicssdk.com/v1/Registration/create \
     --header 'InstanceId: <InstanceId>' \
     --header 'InstanceKey: <InstanceKey>' \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data '{
       "UserFields": {
         "ClientId": "<your-internal-user-id>"
       },
       "CustomToken": "<your-internal-uuid>",
       "CreateAccessToken": false,
       "FirstName": "John",
       "LastName": "Doe",
       "Nickname": "johnny",
       "Phone": "+12345565",
       "Email": "email@mail.com"
     }'
```

### Body fields reference

| Field | Type | Description |
|---|---|---|
| `CustomToken` | UUID string | Your existing internal user UUID. Damoov registers it as `DeviceToken`. Use to avoid maintaining two separate IDs. If omitted, Damoov generates a new UUID. |
| `UserFields.ClientId` | string | Any string identifier from your system (not required to be UUID). |
| `CreateAccessToken` | bool | `false` for backend registration. `true` only for mobile-side flow where you need immediate user JWT. |
| `FirstName`, `LastName`, `Nickname`, `Phone`, `Email` | string | Optional profile fields. |

### CustomToken decision rule

```
if (your internal userId is already a UUID):
    set CustomToken = userId          ← DeviceToken will equal your userId
else:
    omit CustomToken                  ← Damoov generates DeviceToken
    store returned DeviceToken in your DB
```

### Response

```json
{
  "Result": {
    "DeviceToken": "00000000-0000-0000-0000-000000000000",
    "AccessToken": {
      "Token": "...",
      "ExpiresIn": 432000
    },
    "RefreshToken": "..."
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

- `DeviceToken` — **the primary Damoov user identifier.** Also known as UserId or DeviceId — all three terms refer to the same value.
- `AccessToken` — present only when `CreateAccessToken: true`. User-level JWT.
- `AccessToken.ExpiresIn` — 432000 seconds (5 days) when issued via Registration.
  Via Login endpoint it is 86400 seconds (24 hours).

### What to store in backend

```
users table:
  internal_user_id  →  device_token (Damoov UUID)
```

Only `DeviceToken` is needed permanently. `AccessToken` from registration is short-lived;
use User Login to get a fresh JWT when needed.

### What to pass to mobile SDK

Pass **only** `DeviceToken`. The SDK does not need `AccessToken`.

On the mobile side, call the platform-specific setter with this DeviceToken.
For per-platform code snippets and the full handoff flow, see
`../../../mobile/references/devicetoken-flow.md`.

Note: DeviceToken and DeviceId refer to the same value. The SDK method is
`setDeviceID(...)` / `setDeviceId(...)` — not `setDeviceToken` (that name does not exist).

---

## User Login — get user JWT

Use this when the backend needs a user-level JWT for user-context endpoints:
`POST /trips/get/v1/`, `GET /indicators/v3/…` (user's own trips and scores).

> **User Management API (`GET/PUT/DELETE /v1/Management/users/…`) requires Admin JWT — not User JWT.**
> See `../../../backend/damoov-user-management-skill/SKILL.md`.

```bash
curl --request POST \
     --url https://user.telematicssdk.com/v1/Auth/Login \
     --header 'InstanceId: <InstanceId>' \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data '{
       "LoginFields": "{\"Devicetoken\":\"<DeviceToken-UUID>\"}",
       "Password": "<InstanceKey>"
     }'
```

- `InstanceId` header — the instance the user belongs to
- `LoginFields.Devicetoken` — the user's `DeviceToken` (login)
  > **Casing is exact:** the JSON key inside `LoginFields` is `Devicetoken` (lowercase `t`),
  > not `DeviceToken`. A case mismatch causes a `401` with no useful error message.
- `Password` — `InstanceKey` (acts as password)

Response:
```json
{
  "Result": {
    "DeviceToken": "<uuid>",
    "AccessToken": {
      "Token": "<user-jwt>",
      "ExpiresIn": 86400
    },
    "RefreshToken": "<refresh>"
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

User JWT lifetime: **24 hours**. On `401` — refresh via `POST /v1/Auth/RefreshToken`.

### User JWT Refresh

```bash
curl --request POST \
  --url 'https://user.telematicssdk.com/v1/Auth/RefreshToken' \
  --header 'accept: application/json' \
  --header 'content-type: application/json' \
  --data '{
    "AccessToken": "<expired-user-jwt>",
    "RefreshToken": "<user-refresh-token>"
  }'
```

Response: same shape as Admin JWT refresh — `Result.AccessToken.Token` (new 24h JWT) + new `RefreshToken`.
See `admin-auth.md` — "Refresh JWT" section for full response example.

> **`InstanceId` header:** Not required for refresh — only required for User Login.
> **RefreshToken lifetime for User JWT:** ⚠️ unverified — Admin RefreshToken is 3 months.
> User JWT RefreshToken lifetime is not confirmed in live responses or Swagger.
> Assume the same 3-month lifetime until Damoov confirms otherwise.

---

## Get registered users

**Endpoint:** `POST https://user.telematicssdk.com/v1/Management/users/GetFilteredPage`

**Auth:** `Authorization: Bearer <admin-JWT>`

**Content-Type:** `application/json-patch+json`

```bash
curl -X POST \
  'https://user.telematicssdk.com/v1/Management/users/GetFilteredPage' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>' \
  -H 'Content-Type: application/json-patch+json' \
  -d '{
    "InstanceIds": ["<instance-uuid>"],
    "PageNumber": 1,
    "PageSize": 50,
    "IncludeAccountInfo": true,
    "Sort": "DateCreatedDesc",
    "ActivityStatuses": [],
    "ShowInactiveUsers": true
  }'
```

### Request body fields

| Field | Type | Required | Description |
|---|---|---|---|
| `CompanyIds` | `UUID[]` | no | Filter by company (nullable) |
| `ApplicationIds` | `UUID[]` | no | Filter by application (nullable) |
| `InstanceIds` | `UUID[]` | no | Filter by instance (nullable) |
| `PageNumber` | `int` | yes | 1-based page index |
| `PageSize` | `int` | yes | Records per page |
| `IncludeAccountInfo` | `bool` | yes | Include `AccountInfo` block (Company/App/Instance names) |
| `SearchTerm` | `string` | no | Free-text search (nullable) |
| `Sort` | `UserSort` | yes | See enum below |
| `ActivityStatuses` | `ActivityStatus[]` | no | Filter by activity (empty = all) |
| `DateCreatedFrom` | `datetime` | no | ISO 8601, nullable |
| `DateCreatedTo` | `datetime` | no | ISO 8601, nullable |
| `Country` | `string` | no | nullable |
| `City` | `string` | no | nullable |
| `ShowInactiveUsers` | `bool` | yes | Include users with `Status: "Inactive"` |
| `RtdEnabled` | `bool` | no | Filter by real-time data flag (nullable) |

### `Sort` enum values

```
DeviceToken / DeviceTokenDesc
FirstName / FirstNameDesc
LastName / LastNameDesc
Nickname / NicknameDesc
Phone / PhoneDesc
Email / EmailDesc
Gender / GenderDesc
Birthday / BirthdayDesc
MaritalStatus / MaritalStatusDesc
ChildrenCount / ChildrenCountDesc
Country / CountryDesc
District / DistrictDesc
City / CityDesc
DateCreated / DateCreatedDesc     ← most common
ActivityStatus / ActivityStatusDesc
```

### `ActivityStatuses` enum values

```
Active | Inactive | Lost | NoData | Error
```

### Live response sample (Gate 2, 2026-06-12)

```json
{
  "Result": {
    "Users": [
      {
        "DeviceToken": "00000000-0000-0000-0000-000000000000",
        "DateCreated": "2026-06-12T04:51:03.3227368",
        "Status": "Active",
        "ActivityStatus": "No Data",
        "UserProfile": {
          "FirstName": null,
          "LastName": null,
          "Gender": "None",
          "Birthday": null,
          "MaritalStatus": null,
          "ChildrenCount": null,
          "Address": null,
          "Country": null,
          "District": null,
          "City": null,
          "Nickname": null,
          "Email": "email@mail.com",
          "Phone": null,
          "ImageUrl": "https://user.telematicssdk.com/Files/DefaultImages/ic_no_avatar_white.png",
          "ExternalImageUrl": null
        },
        "MobileDevice": {
          "MobileUid": null,
          "DeviceModel": null,
          "OsType": "",
          "OsVersion": null,
          "SdkVersion": null,
          "AppVersion": null,
          "VirtualImei": "000000000000000"
        },
        "AccountInfo": {
          "CompanyId": "00000000-0000-0000-0000-000000000000",
          "CompanyName": "Example Company",
          "ApplicationId": "00000000-0000-0000-0000-000000000000",
          "ApplicationName": "Example Application",
          "InstanceId": "00000000-0000-0000-0000-000000000000",
          "InstanceName": "Example Instance"
        },
        "UserWallets": null,
        "IdentityId": "identity-id-001",
        "IdentityProvider": "firebase",
        "UserFields": [
          {
            "ClientId": null,
            "EnableLogging": false,
            "EnableRealTimeLocation": false,
            "EnableTracking": true,
            "Enabled": true
          }
        ]
      }
    ],
    "HasPreviousPage": false,
    "HasNextPage": true,
    "TotalUsers": 114,
    "TotalPages": 38,
    "CurrentPage": 1
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

### Key observations from live response

- All field names are **PascalCase** (`DeviceToken`, `UserProfile`, `AccountInfo`, etc.)
- `Status` — string: `"Active"` or `"Inactive"` (not int)
- `ActivityStatus` — string: `"No Data"`, `"Active"`, `"Inactive"`, `"Lost"`, `"Error"`
  - Note: in the response the value uses spaces (`"No Data"`), but in the filter body use `"NoData"` (no space)
- `UserProfile` fields are all nullable — expect `null` for most users
- `IdentityId` + `IdentityProvider` — present when user registered via Firebase/identity provider (e.g. email sign-in). Absent (null) for DeviceToken-only users
- `UserFields[0]` contains feature flags: `EnableTracking`, `EnableLogging`, `EnableRealTimeLocation`, `Enabled`
- `AccountInfo` included only when `IncludeAccountInfo: true`
- Pagination: `CurrentPage` is 1-based; use `HasNextPage` to walk all pages
