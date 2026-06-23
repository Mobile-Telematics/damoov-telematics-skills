---
name: damoov-product-management-skill
description: Use when creating, reading, updating, or deleting Damoov Applications and Instances through platform APIs with Admin JWT, including product hierarchy operations, URL casing, live response fields, and destructive-operation safeguards.
---

# damoov-product-management-skill

Covers: creating, reading, updating, and deleting Applications and Instances in the Damoov hierarchy.  
All operations require an Admin JWT. Base URL: `https://accounts.telematicssdk.com`

> **This skill covers write operations and new read methods only.**  
> Hierarchy READ methods already documented in `../damoov-backend-registration-skill/references/hierarchy.md`:
> - `GET /v1/companies/{CompanyId}/applications` — list all Apps in a Company
> - `GET /v1/Applications/{AppId}?includeInstances=true` — also documented here (different context)
> - `GET /v1/Instances/{InstanceId}` — also documented here

For error handling (401/403/422/429): see `../../shared/references/error-handling.md`.

---

## Never do this

- **Never** use Production CompanyId for creating test Applications or Instances.
- **Never** delete an Instance that has active users — the API returns 422. Delete all users first via `DELETE /v1/Management/users/{DeviceToken}`.
- **Never** delete an Application that has users in any of its Instances — API returns 422. Delete all users from all Instances first.
- **Never** normalize URL casing — paths are case-inconsistent by design. Copy verbatim from the decision table.
- **Never** send PATCH Instance params in a JSON body — they must be query string parameters.
- **Never** use Swagger field names in code — live responses use PascalCase (`AppId`, `Id`, `Key`), not camelCase as Swagger suggests.
- **Never** treat `Result: null` with Status 200 as success when reading an Application — it means the App does not exist.

---

## Method decision table

| Task | HTTP | Path | Reference |
|---|---|---|---|
| Create a new Application | `POST` | `/v1/companies/{CompanyId}/applications` | [product-management-api.md](references/product-management-api.md) |
| Get Application details (with Instances) | `GET` | `/v1/Applications/{AppId}?includeInstances=true` | [product-management-api.md](references/product-management-api.md) |
| Update Application name / status / links | `PATCH` | `/v1/Applications/applications/{AppId}` | [product-management-api.md](references/product-management-api.md) |
| Delete an Application | `DELETE` | `/v1/Applications/applications/{AppId}` | [product-management-api.md](references/product-management-api.md) |
| Create a new Instance inside an Application | `POST` | `/v1/applications/{AppId}/instances` | [product-management-api.md](references/product-management-api.md) |
| List all Instances of an Application | `GET` | `/v1/applications/{AppId}/instances` | [product-management-api.md](references/product-management-api.md) |
| Look up an Instance by its InviteCode | `GET` | `/v1/applications/{AppId}/instances/{InviteCode}` | [product-management-api.md](references/product-management-api.md) |
| Get full Instance details by InstanceId | `GET` | `/v1/Instances/{InstanceId}` | [product-management-api.md](references/product-management-api.md) |
| Rename or change status of an Instance | `PATCH` | `/v1/Instances/{InstanceId}?Name=...&Status=...` | [product-management-api.md](references/product-management-api.md) |
| Delete an Instance | `DELETE` | `/v1/Instances/{InstanceId}` | [product-management-api.md](references/product-management-api.md) |

---

## Authentication

All endpoints require an Admin JWT in the `Authorization` header:

```
Authorization: Bearer <admin-jwt>
```

For Admin JWT acquisition see `../damoov-backend-registration-skill/SKILL.md` (Step 1)
or `../damoov-integration-testing-skill/references/admin-auth.md`.

---

## How to get CompanyId

`CompanyId` is required for `POST /v1/companies/{CompanyId}/applications`.

Obtain it from the Permissions API response — field `companiesPermissions[].companyId`:

```
GET https://user.telematicssdk.com/v1/Permissions/Permissions
Authorization: Bearer <admin-jwt>
```

Response excerpt:
```json
{
  "companiesPermissions": [
    { "companyId": "00000000-0000-0000-0000-000000000000", ... }
  ]
}
```

Full Permissions API flow and Branch C walkthrough:
`../damoov-backend-registration-skill/references/hierarchy.md` — Branch C.

---

## Applications — quick guide

### Create Application

Minimum required body: `name`. Use `createDefaultGroup: true` to automatically create a `"Common"` Instance.

```bash
curl -X POST "https://accounts.telematicssdk.com/v1/companies/{CompanyId}/applications" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer <admin-jwt>" \
  -d '{"name": "MyApp", "status": 1, "createDefaultGroup": true}'
```

Response fields (PascalCase):
```
Result.AppId          uuid — the new Application ID
Result.Instances[]
  .Id                 uuid — InstanceId (use for user registration)
  .Key                uuid — InstanceKey (use for user registration)
```

If `createDefaultGroup: true`, the created Instance is named `"Common"` with description `"Default group"`.  
If `createDefaultGroup: false` (or omitted), `Result.Instances` is `[]`.

### Get Application

```bash
curl -X GET "https://accounts.telematicssdk.com/v1/Applications/{AppId}?includeInstances=true" \
  -H "Authorization: Bearer <admin-jwt>"
```

Response fields:
```
Result.Id             uuid — AppId
Result.Name           string
Result.Description    string
Result.Status         string — "Active" | "Deactivated"
Result.Instances[]
  .Id                 uuid — InstanceId
  .Key                uuid — InstanceKey
  .Name               string
  .Status             string — "Active" | "Deactivated"
```

> If the Application does not exist: `Result: null`, HTTP 200 — not 404.

### Update Application

```bash
curl -X PATCH "https://accounts.telematicssdk.com/v1/Applications/applications/{AppId}" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer <admin-jwt>" \
  -d '{"name": "NewName", "status": 1}'
```

Response: `{ "Status": 200, "Title": "", "Errors": [] }` — no `Result` field.

### Delete Application

```bash
curl -X DELETE "https://accounts.telematicssdk.com/v1/Applications/applications/{AppId}" \
  -H "Authorization: Bearer <admin-jwt>"
```

- No users in any Instance → **200**, all Instances cascade-deleted.
- Users exist in any Instance → **422** `"Users exist for this application."`

---

## Instances — quick guide

### Create Instance

```bash
curl -X POST "https://accounts.telematicssdk.com/v1/applications/{AppId}/instances" \
  -H "content-type: application/json" \
  -H "Authorization: Bearer <admin-jwt>" \
  -d '{"name": "MyInstance", "status": 1}'
```

Response fields:
```
Result.Id     uuid — InstanceId (use for user registration)
Result.Key    uuid — InstanceKey (use for user registration)
```

### List Instances

```bash
curl -X GET "https://accounts.telematicssdk.com/v1/applications/{AppId}/instances" \
  -H "Authorization: Bearer <admin-jwt>"
```

Add `?includeDeactivated=true` to include deactivated Instances.

Full InstanceFullViewModel fields per element:
```
Id, Key, Name, Description, Status, InviteCode, AppId, AppName, CompanyId
```

### Get Instance details

By InstanceId:
```bash
curl -X GET "https://accounts.telematicssdk.com/v1/Instances/{InstanceId}" \
  -H "Authorization: Bearer <admin-jwt>"
```

By InviteCode (when InstanceId is unknown):
```bash
curl -X GET "https://accounts.telematicssdk.com/v1/applications/{AppId}/instances/{InviteCode}" \
  -H "Authorization: Bearer <admin-jwt>"
```

Both return the same full InstanceFullViewModel.

### Update Instance

**Params go in query string — not in body:**

```bash
curl -X PATCH "https://accounts.telematicssdk.com/v1/Instances/{InstanceId}?Name=NewName&Status=1" \
  -H "Authorization: Bearer <admin-jwt>"
```

Available query params: `Name`, `Description`, `Status` (all optional).  
Response: `{ "Status": 200, "Title": "", "Errors": [] }` — no `Result` field.

### Delete Instance

```bash
curl -X DELETE "https://accounts.telematicssdk.com/v1/Instances/{InstanceId}" \
  -H "Authorization: Bearer <admin-jwt>"
```

- No users in Instance → **200**.
- Users exist → **422** `"Can't update instance, because users exists in instance."`

---

## Deletion constraints

The constraint chain flows from users upward through the hierarchy:

```
User → Instance → Application → Company
```

| What you want to delete | Precondition | On violation |
|---|---|---|
| Instance | No users in that Instance | 422 `InstanceId: "Can't update instance, because users exists in instance."` |
| Application | No users in any of its Instances | 422 `AppToken: "Users exist for this application."` |

**Correct deletion order:**
1. **Enumerate users per Instance** using `POST /v1/Management/users/GetFilteredPage` with body `{"Filters": [{"Name": "InstanceId", "Value": "<InstanceId>"}]}`.
   Full curl and response: `../damoov-integration-testing-skill/references/registration-api.md` — "GetFilteredPage" section.
2. For each user found: `DELETE /v1/Management/users/{DeviceToken}` (User API — `user.telematicssdk.com`)
3. Delete each Instance: `DELETE /v1/Instances/{InstanceId}` (optional if deleting the App)
4. Delete Application: `DELETE /v1/Applications/applications/{AppId}` (cascades remaining empty Instances)

> Company deletion has no API — use the Datahub UI.

---

## Status values

| Integer (in requests) | String (in responses) |
|---|---|
| `1` | `"Active"` |
| `2` | `"Deactivated"` |

---

## Response shape reference

| Endpoint | `Result` type | Key fields |
|---|---|---|
| Create App | object | `AppId`, `Instances[]{Id, Key}` |
| Get App | object | `Id`, `Name`, `Status`, `Instances[]{Id, Key, Name, Status}` |
| Create Instance | object | `Id` (InstanceId), `Key` (InstanceKey) |
| List Instances | array | `Id`, `Key`, `Name`, `Description`, `Status`, `InviteCode`, `AppId`, `AppName`, `CompanyId` |
| Get Instance (by Id or InviteCode) | object (same as List element) | same as above |
| PATCH App / PATCH Instance / DELETE | no `Result` | `{ "Status": 200, "Title": "", "Errors": [] }` |
