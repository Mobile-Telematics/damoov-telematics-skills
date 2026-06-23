# User Management API

All endpoints require `Authorization: Bearer <admin-jwt>`.
Base URL: `https://user.telematicssdk.com`

---

## Find User

**Endpoint:** `GET /v1/Management/users/find`

Search by one or more query parameters. Returns all matching users in a single array (no pagination).

Multiple parameters are combined with **AND** — only users matching all specified conditions are returned.

```bash
curl -X GET \
  'https://user.telematicssdk.com/v1/Management/users/find?DeviceToken=<uuid>' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>'
```

### Query parameters

| Param | Type | Description |
|---|---|---|
| `DeviceToken` | UUID | Exact DeviceToken match |
| `Email` | string | User email |
| `Phone` | string | User phone |
| `ClientId` | string | Your internal user ID (from `UserFields.ClientId`) |
| `FirstName` | string | |
| `LastName` | string | |
| `FullName` | string | |

### Live response sample (Gate 2, 2026-06-12)

```json
{
  "Result": [
    {
      "DeviceToken": "00000000-0000-0000-0000-000000000000",
      "DateCreated": "2024-10-29T11:53:57.108485",
      "Status": "Active",
      "ActivityStatus": "Active",
      "UserProfile": {
        "FirstName": "John",
        "LastName": "Doe",
        "Gender": "None",
        "Birthday": "1989-02-17T00:00:00",
        "MaritalStatus": null,
        "ChildrenCount": null,
        "Address": null,
        "Country": null,
        "District": null,
        "City": null,
        "Nickname": null,
        "Email": "email@mail.com",
        "Phone": "+12345565",
        "ImageUrl": "https://user.telematicssdk.com/Files/DefaultImages/ic_no_avatar_white.png",
        "ExternalImageUrl": "https://damoov-shareddocuments.s3.us-east-2.amazonaws.com/opensourceapp/Default_icon.png"
      },
      "MobileDevice": {
        "MobileUid": null,
        "DeviceModel": null,
        "OsType": null,
        "OsVersion": null,
        "SdkVersion": null,
        "AppVersion": null,
        "VirtualImei": "000000000000000"
      },
      "AccountInfo": {
        "CompanyId": "00000000-0000-0000-0000-000000000000",
        "CompanyName": null,
        "ApplicationId": "00000000-0000-0000-0000-000000000000",
        "ApplicationName": null,
        "InstanceId": "00000000-0000-0000-0000-000000000000",
        "InstanceName": null
      },
      "UserWallets": [],
      "IdentityId": "identity-id-001",
      "IdentityProvider": "Firebase",
      "UserFields": [
        {
          "ClientId": "client-id-001",
          "EnableLogging": true,
          "EnableRealTimeLocation": true,
          "EnableTracking": true,
          "Enabled": true
        }
      ]
    }
  ],
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

### Key observations

- `Result` is always **an array** — even for exact DeviceToken lookup
- `AccountInfo.CompanyName`, `ApplicationName`, `InstanceName` are `null` without `IncludeAccountInfo=true`
- `IdentityProvider` casing: `/find` returns `"Firebase"` (capital F); `GetFilteredPage` returns `"firebase"` (lowercase) — do not compare case-sensitively
- `UserFields` is an array with one object; access flags as `UserFields[0].EnableTracking`

---

## List / Filter Users (GetFilteredPage)

**Endpoint:** `POST /v1/Management/users/GetFilteredPage`

Use when you need to enumerate all users in an Instance or apply multiple filters with pagination.

```bash
curl -X POST "https://user.telematicssdk.com/v1/Management/users/GetFilteredPage" \
  -H "Authorization: Bearer <admin-jwt>" \
  -H "content-type: application/json" \
  -d '{
    "Filters": [{"Name": "InstanceId", "Value": "<InstanceId>"}],
    "Pagination": {"Page": 1, "PageSize": 50}
  }'
```

Response contains `Result.Users[]` with the same user object shape as `/find`.

Full filter options and live response: `../../../testing/damoov-integration-testing-skill/references/registration-api.md` — "GetFilteredPage" section.

---

## Update User

**Endpoint:** `PUT /v1/Management/users`

Updates profile fields, service flags, or both. Target user is specified via header, not body.

**Headers:**
- `Authorization: Bearer <admin-jwt>`
- `UserDeviceToken: <device-token-of-user-to-update>`
- `Content-Type: application/json-patch+json`

### Profile fields

```bash
curl -X PUT \
  'https://user.telematicssdk.com/v1/Management/users' \
  -H 'accept: application/json' \
  -H 'UserDeviceToken: <device-token>' \
  -H 'Authorization: Bearer <admin-jwt>' \
  -H 'Content-Type: application/json-patch+json' \
  -d '{
    "FirstName": "John",
    "LastName": "Doe",
    "Nickname": "johnny",
    "Phone": "+12345565",
    "Email": "email@mail.com",
    "Gender": "None",
    "Birthday": "1990-01-01T00:00:00Z",
    "ExternalImageUrl": "https://...",
    "UserFields": {"ClientId": "client-id-001"}
  }'
```

### Service flags

```bash
curl -X PUT \
  'https://user.telematicssdk.com/v1/Management/users' \
  -H 'accept: application/json' \
  -H 'UserDeviceToken: <device-token>' \
  -H 'Authorization: Bearer <admin-jwt>' \
  -H 'Content-Type: application/json-patch+json' \
  -d '{
    "UserFields": {
      "Enabled": true,
      "EnableTracking": true,
      "EnableLogging": true,
      "EnableRealTimeLocation": true
    }
  }'
```

### Full body schema (`UpdateUserCommandDataContractBody`)

| Field | Type | Nullable | Notes |
|---|---|---|---|
| `FirstName` | string | yes | |
| `LastName` | string | yes | |
| `Nickname` | string | yes | |
| `Phone` | string | yes | |
| `Email` | string | yes | |
| `Gender` | string enum | — | `None` / `Male` / `Female` / `Other` |
| `Birthday` | datetime | yes | ISO 8601 |
| `MaritalStatus` | string | yes | |
| `ChildrenCount` | int | yes | |
| `Country` | string | yes | |
| `District` | string | yes | |
| `City` | string | yes | |
| `Address` | string | yes | |
| `ExternalImageUrl` | string | yes | Custom avatar URL |
| `Status` | string enum | — | `Active` / `Deactivated` / `Deleted` |
| `OldPassword` | string | yes | |
| `NewPassword` | string | yes | |
| `IdentityId` | string | yes | Identity provider user ID |
| `IdentityProvider` | string | yes | e.g. `"Firebase"` |
| `UserFields` | object | yes | `ClientId`, `Enabled`, `EnableTracking`, `EnableLogging`, `EnableRealTimeLocation` |

### `UserFields` flags

| Flag | Effect |
|---|---|
| `Enabled` | Master switch — enables/disables the user account in the system |
| `EnableTracking` | Allows trip recording |
| `EnableLogging` | Allows debug logging |
| `EnableRealTimeLocation` | Allows live GPS position streaming |
| `ClientId` | Your internal user identifier (stored for lookup by ClientId in `/find`) |

### Live response (Gate 2, 2026-06-12)

```json
{
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

Response body contains no user data — only the status code. On success `Status` is `200`.

### User `Status` field — read vs write reconciliation

The `Status` field has different valid values depending on direction:

| Direction | Values | Where |
|---|---|---|
| **Read** (GET `/find`, POST `GetFilteredPage`) | `"Active"`, `"Inactive"` | `Result[].Status` |
| **Write** (PUT body) | `"Active"`, `"Deactivated"`, `"Deleted"` | `Status` field in request body |

Note: `"Inactive"` in read responses corresponds to `"Deactivated"` as a write value.
`"Deleted"` via PUT is a soft state; `DELETE /v1/Management/users/{DeviceToken}` is a hard (irreversible) removal.

### `UserFields` shape — read vs write

| Direction | Shape | Example |
|---|---|---|
| **Read** | Array with one object | `"UserFields": [{ "EnableTracking": true, ... }]` → access as `UserFields[0].EnableTracking` |
| **Write** | Object | `"UserFields": { "EnableTracking": true, ... }` |

---

## Delete User

**Endpoint:** `DELETE /v1/Management/users/{DeviceToken}`

**IRREVERSIBLE.** Deletes the user record and ALL associated telematics data. No recovery possible.

```bash
curl -X DELETE \
  'https://user.telematicssdk.com/v1/Management/users/<device-token>' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>'
```

### Live response (Gate 2, 2026-06-12)

```json
{
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Rules:**
- Never call without explicit confirmation from an operator or system with GDPR delete intent
- There is no soft-delete or archive — `Status: "Deleted"` via PUT is a soft state; DELETE is hard removal
- Verify the DeviceToken belongs to the expected user via `/find` before calling DELETE

---

## Change User Instance

Move a user from their current Instance to a different one. Requires knowing the target
`InstanceId` and `InstanceKey` (see `../../damoov-backend-registration-skill/references/hierarchy.md`).

**Endpoint:** `POST /v1/Management/users/instances/change`

```bash
curl -X POST \
  'https://user.telematicssdk.com/v1/Management/users/instances/change' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>' \
  -H 'Content-Type: application/json-patch+json' \
  -d '{
    "DeviceToken": "<user-device-token>",
    "ToInstanceId": "<target-instance-id>",
    "ToInstanceKey": "<target-instance-key>"
  }'
```

### Body fields (`ChangeUserInstanceDataContract`)

| Field | Type | Description |
|---|---|---|
| `DeviceToken` | UUID | The user to move |
| `ToInstanceId` | UUID | Target Instance ID |
| `ToInstanceKey` | UUID | Target Instance Key (acts as credential, not a UUID in the API sense but formatted as one) |

### Live response (Gate 2, 2026-06-12)

```json
{
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Note:** `docs.damoov.com` shows `Toinstancekey` (lowercase `k`) — this is a documentation typo.
Use `ToInstanceKey` (PascalCase) as confirmed by Swagger and live curl.
