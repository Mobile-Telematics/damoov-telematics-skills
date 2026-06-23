---
name: damoov-backend-registration-skill
description: Use when implementing Damoov DeviceToken registration in a backend service. Covers production registration flow, hierarchy resolution from admin JWT, admin auth lifecycle, User JWT issuance, and the security pattern for keeping InstanceKey server-side.
---

# Damoov Backend Registration Skill

Use this skill when writing server-side code that:
- Registers new users with the Damoov platform and receives a DeviceToken
- Resolves the Damoov hierarchy (Company → Application → Instance) from admin credentials
- Issues User JWTs to mobile clients via a backend proxy

---

## Never do this

- **Never** embed `InstanceKey` in a mobile app binary or return it to a mobile client.
  `InstanceKey` is an instance-level secret — treat it like a database password.
- **Never** return a User JWT to a mobile client without issuing it through a backend endpoint
  that the client authenticates to first (see "Secure User JWT issuance" below).
- **Never** call `POST /v1/Auth/Login` more than 5 times per minute per IP — exceeding this triggers a 1-hour block. Always cache the JWT and use Refresh on 401.
  On 429: if you have a `RefreshToken` → use it; if cold start (no RefreshToken yet) → wait 1 hour or use a different IP.
- **Never** store only `AccessToken` — always store `RefreshToken` alongside it (RefreshToken lives 3 months).
- **Never** call `setDeviceToken(...)` in mobile SDK code — the current API is `setDeviceID` / `setDeviceId` (see `../../mobile/references/devicetoken-flow.md`).

---

## Core concepts

```
Company
  └── Application  (one or more per Company)
        └── Instance  (one or more per Application)
              └── Users (each user registered into one Instance)
```

- **InstanceId + InstanceKey** — instance-level registration credentials. Required headers for `POST /v1/Registration/create`.
- **DeviceToken** — UUID returned after registration. The primary Damoov user identifier. Also called `UserId` or `DeviceId` — all three refer to the same value.
- **Admin JWT** — company/app/instance-level JWT obtained via `POST /v1/Auth/Login`. Used for management API calls.
- **User JWT** — user-level JWT obtained via `POST /v1/Auth/Login` with `DeviceToken` as login and `InstanceKey` as password. Used for User Management API calls on behalf of a specific user.

---

## Step 1 — Get admin JWT

See `../../testing/damoov-integration-testing-skill/references/admin-auth.md` for the full
login, cache, and refresh flow including rate-limit rules.

**Summary:**
```bash
curl --request POST \
  --url 'https://user.telematicssdk.com/v1/Auth/Login' \
  --header 'content-type: application/json' \
  --data '{"LoginFields":"{\"email\":\"<admin-email>\"}","Password":"<admin-password>"}'
```

Cache `Result.AccessToken.Token` (24h) and `Result.RefreshToken` (3 months).
On any API `401` → call `POST /v1/Auth/RefreshToken`, not Login.

---

## Step 2 — Get InstanceId + InstanceKey

**Option A — Static (recommended for single-instance production setups)**

Copy from Datahub → **Control Panel** → **Hierarchy Management** → Instance ⋮ → Copy InstanceId / Copy InstanceKey. Store in environment variables. No API call needed.

**Option B — Dynamic (multi-instance routing or agent-driven setup)**

Resolve from the admin JWT at runtime. See `references/hierarchy.md` for the full flow:

```bash
# 1. Determine access scope
GET https://portal-apis.telematicssdk.com/auth/permissions
Authorization: Bearer <admin-jwt>

# 2. Based on non-empty array in response, call Accounts API:
#    instancesPermissions → GET /v1/Instances/{instanceId}         → Result.Id, Result.Key
#    appsPermissions      → GET /v1/Applications/{appId}?includeInstances=true → Result.Instances[].Id, .Key
#    companiesPermissions → GET /v1/companies/{companyId}/applications → then app branch above
```

> **Cannot create a Company via API.**
> Companies are created during sign-up on the Damoov platform (web UI).
> If you need a new Company, register at the Damoov portal — `CompanyId` will be
> assigned automatically. Then retrieve it via the Permissions API as described above.

---

## Step 3 — Register a user

```bash
curl --request POST \
     --url https://user.telematicssdk.com/v1/Registration/create \
     --header 'InstanceId: <InstanceId>' \
     --header 'InstanceKey: <InstanceKey>' \
     --header 'content-type: application/json' \
     --data '{
       "UserFields": { "ClientId": "<your-internal-user-id>" },
       "CustomToken": "<your-internal-uuid-if-applicable>",
       "CreateAccessToken": false
     }'
```

`CustomToken` rule:
- If your internal userId is already a UUID → set `CustomToken = userId`. Damoov registers it as `DeviceToken` so both IDs match.
- Otherwise → omit `CustomToken`. Damoov generates a new UUID. Store the returned `Result.DeviceToken` in your DB.

**Store:** `internalUserId → DeviceToken` in your users table. The DeviceToken is permanent.

**Pass to mobile:** Return `DeviceToken` in your login/session response. The mobile app calls `setDeviceID(deviceToken)` — see `../../mobile/references/devicetoken-flow.md`.

Full schema: `../../testing/damoov-integration-testing-skill/references/registration-api.md`.

---

## Secure User JWT issuance

A User JWT is required for user-scoped API calls (User Management, user-context Trips/Indicators).

**Security rule:** `InstanceKey` must stay on the backend. Do NOT expose it to mobile clients.
Implement a backend endpoint that:
1. Authenticates the client (your own auth — e.g. session cookie, OAuth token).
2. Looks up the user's `DeviceToken` from your DB.
3. Calls the Damoov User Login API server-side.
4. Returns only the `AccessToken.Token` (User JWT) to the client.

```bash
# Backend calls this on behalf of the authenticated client:
curl --request POST \
     --url https://user.telematicssdk.com/v1/Auth/Login \
     --header 'InstanceId: <InstanceId>' \
     --header 'content-type: application/json' \
     --data '{
       "LoginFields": "{\"Devicetoken\":\"<DeviceToken-UUID>\"}",
       "Password": "<InstanceKey>"
     }'
```

Response: `Result.AccessToken.Token` is the User JWT (24h lifetime when issued via Login).
Note: Registration-issued `AccessToken` (when `CreateAccessToken: true`) has 432000s lifetime (5 days).
Production flow always uses `CreateAccessToken: false` — only DeviceToken is stored.
Refresh via `POST /v1/Auth/RefreshToken` — same endpoint as admin refresh.

---

## Admin JWT lifecycle

```
App startup → POST /v1/Auth/Login (once)
  → cache Token (24h) + RefreshToken (3 months)

Every API call:
  → use cached Token
  → on 401 → POST /v1/Auth/RefreshToken → update cache
  → after 3 months → POST /v1/Auth/Login again
```

Rate limit: 5 Login calls / minute / IP — exceeding triggers a 1-hour block. Returns `429`.

---

## References

- `references/hierarchy.md` — Accounts API: full hierarchy resolution from admin JWT
- `../../testing/damoov-integration-testing-skill/references/admin-auth.md` — admin login, refresh, rate-limit rules
- `../../testing/damoov-integration-testing-skill/references/registration-api.md` — Registration API full schema
- `../../mobile/references/devicetoken-flow.md` — Mobile SDK DeviceToken handoff
- `../../backend/damoov-user-management-skill/SKILL.md` — user find, update, delete (requires admin JWT)
