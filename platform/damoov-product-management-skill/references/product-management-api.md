# Damoov Product Management API — reference

Base URL: `https://accounts.telematicssdk.com`  
Auth: `Authorization: Bearer <admin-jwt>` on every request.  
See `damoov-user-registration-skill` for Admin JWT acquisition.

---

## Critical notes (read first)

- **URL casing is intentional and inconsistent** — copy verbatim. Do not normalize case.
  - Create App: `/v1/companies/` (lowercase c)
  - Get App: `/v1/Applications/` (uppercase A)
  - Update/Delete App: `/v1/Applications/applications/` (mixed — both levels)
  - Create/List Instances: `/v1/applications/` (lowercase a)
  - Get/Update/Delete Instance: `/v1/Instances/` (uppercase I)
- **All live responses return PascalCase** (`AppId`, `Id`, `Key`, `Name`, `Status`, `InviteCode`) — Swagger shows camelCase but that is incorrect.
- **`Status` in responses is a string** (`"Active"`, `"Deactivated"`). In request bodies it is an integer (`1` = Active, `2` = Deactivated).
- **PATCH Instance uses query params, not a JSON body** — unlike PATCH Application which uses JSON body.
- **GET App returns `Result: null` with Status 200 if App does not exist** — not a 404.

---

## Swagger source

`https://accounts.telematicssdk.com/swagger/v1/swagger.json` (2026-06-16)

---

## Application endpoints

### POST `/v1/companies/{CompanyId}/applications` — Create Application

**Required path param:** `CompanyId`

```bash
curl -X POST "https://accounts.telematicssdk.com/v1/companies/{CompanyId}/applications" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer <admin-jwt>" \
  -d '{
    "name": "MyApp",
    "description": "optional description",
    "status": 1,
    "createDefaultGroup": true
  }'
```

**Request body fields:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | Yes | string | — |
| `description` | No | string | — |
| `status` | No | integer | `1` = Active (default), `2` = Deactivated |
| `googlePlayLink` | No | string | — |
| `appleStoreLink` | No | string | — |
| `environment` | No | string | — |
| `createDefaultGroup` | No | boolean | If `true`, automatically creates an Instance named `"Common"` with description `"Default group"` |

**Live response (2026-06-16):**

```json
{
  "Result": {
    "AppId": "00000000-0000-0000-0000-000000000000",
    "Instances": [
      {
        "Id": "00000000-0000-0000-0000-000000000000",
        "Key": "00000000-0000-0000-0000-000000000000"
      }
    ]
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observations:**
- Response is PascalCase (`AppId`, `Instances`, `Id`, `Key`) — Swagger shows camelCase, that is wrong
- `createDefaultGroup: true` creates an Instance named `"Common"` with description `"Default group"` automatically
- `Instances` in response contains only `Id` (InstanceId) + `Key` (InstanceKey) — immediately usable for user registration
- `Instances` is an empty array `[]` if `createDefaultGroup: false` or omitted

---

### GET `/v1/Applications/{AppId}` — Get Application

**Required path param:** `AppId`  
**Optional query param:** `includeInstances=true`

```bash
curl -X GET "https://accounts.telematicssdk.com/v1/Applications/{AppId}?includeInstances=true" \
  -H "Authorization: Bearer <admin-jwt>"
```

**Live response (2026-06-16):**

```json
{
  "Result": {
    "Id": "00000000-0000-0000-0000-000000000000",
    "Name": "Example Application",
    "Description": "...",
    "Status": "Active",
    "GooglePlayLink": null,
    "AppleStoreLink": null,
    "Environment": null,
    "Instances": [
      {
        "Id": "00000000-0000-0000-0000-000000000000",
        "Key": "00000000-0000-0000-0000-000000000000",
        "Name": "Example Instance",
        "Status": "Active"
      }
    ]
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observations:**
- `Status` in response is a string (`"Active"`), not integer
- Instances in Get App response: only `Id`, `Key`, `Name`, `Status` — not full InstanceFullViewModel
- Unset fields (`GooglePlayLink`, `AppleStoreLink`, `Environment`) are `null`, not absent
- **Returns `Result: null` with HTTP 200 if App does not exist** — not a 404

---

### PATCH `/v1/Applications/applications/{AppId}` — Update Application

**Required path param:** `AppId`

```bash
curl -X PATCH "https://accounts.telematicssdk.com/v1/Applications/applications/{AppId}" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer <admin-jwt>" \
  -d '{"name": "NewName", "description": "...", "status": 1}'
```

**Request body fields:** same as Create Application, all optional.

**Live response (2026-06-16):**

```json
{ "Status": 200, "Title": "", "Errors": [] }
```

No `Result` field in response.

---

### DELETE `/v1/Applications/applications/{AppId}` — Delete Application

**Required path param:** `AppId`

```bash
curl -X DELETE "https://accounts.telematicssdk.com/v1/Applications/applications/{AppId}" \
  -H "Authorization: Bearer <admin-jwt>"
```

**Live response — success (2026-06-16):**

```json
{ "Status": 200, "Title": "", "Errors": [] }
```

**Live response — 422 (users exist in any Instance):**

```json
{
  "Status": 422,
  "Title": "One or more validation errors occurred.",
  "Errors": [
    {
      "Key": "AppToken",
      "Message": "Users exist for this application."
    }
  ]
}
```

**Deletion rules (verified live):**
- App with no users in any Instance → **200**, all Instances are cascade-deleted
- App with users in any Instance → **422** `"Users exist for this application."`
- After deletion: GET App returns `Result: null` (Status 200)
- After deletion: DELETE an Instance of the deleted App → `403 Forbidden` or `404 Not Found`

---

## Instance endpoints

### POST `/v1/applications/{AppId}/instances` — Create Instance

**Required path param:** `AppId`

```bash
curl -X POST "https://accounts.telematicssdk.com/v1/applications/{AppId}/instances" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer <admin-jwt>" \
  -d '{"name": "MyInstance", "description": "...", "status": 1}'
```

**Request body fields:**

| Field | Required | Type | Notes |
|---|---|---|---|
| `name` | Yes | string | — |
| `description` | No | string | — |
| `status` | No | integer | `1` = Active (default), `2` = Deactivated |

**Live response (2026-06-16):**

```json
{
  "Result": {
    "Id": "00000000-0000-0000-0000-000000000000",
    "Key": "00000000-0000-0000-0000-000000000000"
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observation:** `Result.Id` = InstanceId, `Result.Key` = InstanceKey — immediately usable for user registration.

---

### GET `/v1/applications/{AppId}/instances` — List Instances of App

**Required path param:** `AppId`  
**Optional query param:** `includeDeactivated=true`

```bash
curl -X GET "https://accounts.telematicssdk.com/v1/applications/{AppId}/instances" \
  -H "Authorization: Bearer <admin-jwt>"
```

**Live response (2026-06-16) — full InstanceFullViewModel:**

```json
{
  "Result": [
    {
      "Id": "00000000-0000-0000-0000-000000000000",
      "Key": "00000000-0000-0000-0000-000000000000",
      "Name": "Example Instance",
      "Description": "Default group",
      "Status": "Active",
      "InviteCode": "EXAMPLE",
      "AppId": "00000000-0000-0000-0000-000000000000",
      "AppName": "Example Application",
      "CompanyId": "00000000-0000-0000-0000-000000000000"
    }
  ],
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observation:** `AppName` reflects the latest updated name of the parent Application.

---

### GET `/v1/applications/{AppId}/instances/{InviteCode}` — Get Instance by InviteCode

**Required path params:** `AppId`, `InviteCode`

```bash
curl -X GET "https://accounts.telematicssdk.com/v1/applications/{AppId}/instances/{InviteCode}" \
  -H "Authorization: Bearer <admin-jwt>"
```

Response: identical to a single element from List Instances (full InstanceFullViewModel).

---

### GET `/v1/Instances/{InstanceId}` — Get Instance details

**Required path param:** `InstanceId`

```bash
curl -X GET "https://accounts.telematicssdk.com/v1/Instances/{InstanceId}" \
  -H "Authorization: Bearer <admin-jwt>"
```

Response: identical to Get Instance by InviteCode — full InstanceFullViewModel.

---

### PATCH `/v1/Instances/{InstanceId}` — Update Instance

**Required path param:** `InstanceId`  
**Parameters go in query string — NOT in body.**

```bash
curl -X PATCH "https://accounts.telematicssdk.com/v1/Instances/{InstanceId}?Name=NewName&Description=...&Status=1" \
  -H "Authorization: Bearer <admin-jwt>"
```

**Query params:**

| Param | Type | Notes |
|---|---|---|
| `Name` | string | Optional |
| `Description` | string | Optional |
| `Status` | integer | Optional — `1` = Active, `2` = Deactivated |

**Live response (2026-06-16):**

```json
{ "Status": 200, "Title": "", "Errors": [] }
```

No `Result` field in response.

---

### DELETE `/v1/Instances/{InstanceId}` — Delete Instance

**Required path param:** `InstanceId`

```bash
curl -X DELETE "https://accounts.telematicssdk.com/v1/Instances/{InstanceId}" \
  -H "Authorization: Bearer <admin-jwt>"
```

**Live response — success (2026-06-16):**

```json
{ "Status": 200, "Title": "", "Errors": [] }
```

**Live response — 422 (users exist in Instance):**

```json
{
  "Status": 422,
  "Title": "One or more validation errors occurred.",
  "Errors": [
    {
      "Key": "InstanceId",
      "Message": "Can't update instance, because users exists in instance."
    }
  ]
}
```

**Deletion rule:** Delete all users via `DELETE /v1/Management/users/{DeviceToken}` (**User API** — `user.telematicssdk.com`, not Accounts API) before deleting an Instance.

---

## Full endpoint table

| # | Operation | HTTP | Path | Body / Params |
|---|---|---|---|---|
| 1 | Create Application | `POST` | `/v1/companies/{CompanyId}/applications` | JSON body |
| 2 | Get Application | `GET` | `/v1/Applications/{AppId}` | `?includeInstances=true` |
| 3 | Update Application | `PATCH` | `/v1/Applications/applications/{AppId}` | JSON body |
| 4 | Delete Application | `DELETE` | `/v1/Applications/applications/{AppId}` | none |
| 5 | Create Instance | `POST` | `/v1/applications/{AppId}/instances` | JSON body |
| 6 | List Instances | `GET` | `/v1/applications/{AppId}/instances` | `?includeDeactivated=true` |
| 7 | Get Instance by InviteCode | `GET` | `/v1/applications/{AppId}/instances/{InviteCode}` | none |
| 8 | Get Instance details | `GET` | `/v1/Instances/{InstanceId}` | none |
| 9 | Update Instance | `PATCH` | `/v1/Instances/{InstanceId}` | **query params** (not body) |
| 10 | Delete Instance | `DELETE` | `/v1/Instances/{InstanceId}` | none |

---

## Known Swagger vs live discrepancies

| Issue | Swagger says | Live response |
|---|---|---|
| Response field casing | camelCase (`appId`, `id`, `key`) | PascalCase (`AppId`, `Id`, `Key`) |
| `Status` in response | integer | string (`"Active"`, `"Deactivated"`) |
| Not-found behavior | 404 | 200 with `Result: null` |
| PATCH Instance params | body JSON | query string |
