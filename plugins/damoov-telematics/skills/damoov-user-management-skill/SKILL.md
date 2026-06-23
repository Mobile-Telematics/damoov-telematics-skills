---
name: damoov-user-management-skill
description: Use when managing existing Damoov telematics users through platform APIs, including finding users, updating profile or service flags, deleting users, moving users between Instances, and enabling Real-Time Location Data.
---

# Damoov User Management Skill

Use this skill when managing existing Damoov telematics users from a backend service
or an automated agent. Covers finding users, updating profile and service flags,
deleting users, and moving users between Instances.

All methods require **Admin JWT**.
- How to obtain: `../damoov-backend-registration-skill/SKILL.md` (Step 1) or `../damoov-integration-testing-skill/references/admin-auth.md`

For error handling (401/403/422/429): see `../../shared/references/error-handling.md`.

---

## Operating Rules (never violate)

1. **DELETE is irreversible.** `DELETE /v1/Management/users/{DeviceToken}` permanently removes the
   user and all associated telematics data. Always require explicit confirmation before calling.
   Never call it speculatively.
2. **UserDeviceToken header selects the target user for PUT.** The body does not contain the
   DeviceToken for updates — the target user is set via `UserDeviceToken: <uuid>` request header.
3. **`Result` from `/find` is always an array.** Even when searching by exact DeviceToken,
   the response is `"Result": [...]`. Do not assume a single object.
4. **Use `ToInstanceKey` (PascalCase) for instance changes.** The docs.damoov.com page shows
   `Toinstancekey` — this is a documentation typo. Use `ToInstanceKey` as shown in Swagger.
5. **Profile update and service flags use the same endpoint.** `PUT /v1/Management/users`
   handles both; the body determines what changes. You may combine them in one call.

---

## Method decision table

| What you need to do | Method | Endpoint |
|---|---|---|
| Find user by DeviceToken, Email, Phone, ClientId, or name | `GET` | `/v1/Management/users/find` |
| Update profile fields (name, email, phone, gender, birthday…) | `PUT` | `/v1/Management/users` |
| Update service flags (Enabled, EnableTracking, EnableLogging…) | `PUT` | `/v1/Management/users` |
| Delete user permanently | `DELETE` | `/v1/Management/users/{DeviceToken}` |
| Move user to a different Instance | `POST` | `/v1/Management/users/instances/change` |

---

## When to use `/find` vs `GetFilteredPage`

| Use case | Endpoint |
|---|---|
| Look up one specific user by DeviceToken, Email, Phone, or ClientId | `GET /v1/Management/users/find` |
| Browse / filter all users with pagination and sorting | `POST /v1/Management/users/GetFilteredPage` |

`/find` does not paginate and returns all matching users in one array.
`GetFilteredPage` is documented in `../damoov-integration-testing-skill/references/registration-api.md`.

---

## Enable Real-Time Location Data (RTD)

To enable live GPS streaming for a user, set `UserFields.EnableRealTimeLocation: true` via
`PUT /v1/Management/users` — see `references/user-management-api.md` — "Update user" section.

RTD also requires Datahub-level configuration and SDK delegate setup.
Full three-level flow: `../../shared/references/rtld-flow.md`.

---

## References

- `references/user-management-api.md` — all 5 methods with exact curls and live responses
- `../damoov-integration-testing-skill/references/admin-auth.md` — Admin JWT login and refresh
- `../damoov-backend-registration-skill/references/hierarchy.md` — resolve ToInstanceId + ToInstanceKey
