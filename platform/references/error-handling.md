# Damoov API — Error Handling Reference

Applies to all platform skills: user-management, trips-statistics, product-management.

---

## Platform Overview

| Base URL | Skill | JWT type |
|---|---|---|
| `https://user.telematicssdk.com` | user-management, trips (user variant `/trips/get/v1/`), indicators (`/indicators/v3/`) | Admin JWT **or** User JWT (depends on endpoint) |
| `https://accounts.telematicssdk.com` | product-management (Applications/Instances CRUD) | Admin JWT |
| `https://api.telematicssdk.com` | trips-statistics (trips, indicators) | Admin JWT **or** User JWT (depends on endpoint) |
| `https://portal-apis.telematicssdk.com` | hierarchy permissions (`/v1/Permissions/Permissions`) | Admin JWT |

**Admin JWT** — obtained via `POST https://user.telematicssdk.com/v1/Auth/Login` with email + password.
See `../../backend/damoov-backend-registration-skill/references/admin-auth.md` or
`../../testing/damoov-integration-testing-skill/references/admin-auth.md`.

**User JWT** — obtained via `POST https://user.telematicssdk.com/v1/Auth/Login` with DeviceToken + InstanceKey.
See `../../testing/damoov-integration-testing-skill/references/registration-api.md` — "User Login" section.

---

## HTTP Error Reference

| Status | Situation | Action |
|---|---|---|
| `401` | JWT expired | Refresh via `POST /v1/Auth/RefreshToken` (do not re-login) |
| `401` (after refresh) | RefreshToken expired | Login again via `POST /v1/Auth/Login` |
| `403` | Wrong JWT type | Check that you are using Admin JWT where required; User JWT cannot call admin endpoints |
| `403` / `422` | Missing `UserDeviceToken` header on `PUT /v1/Management/users` | The header `UserDeviceToken: <target-user-DeviceToken>` is required for all user update calls. Verify it is present and contains the **target user's** DeviceToken, not the caller's. |
| `404` | Entity not found | Standard 404 — entity does not exist |
| `200` + `Result: null` | Entity not found (Accounts API) | Accounts API (`accounts.telematicssdk.com`) returns HTTP 200 with `Result: null` instead of 404 for missing Applications/Instances. Always check `Result !== null` |
| `422` | Validation or constraint error | Read `Errors[]` in response body; for delete operations — remove child entities first (users → instances → app) |
| `429` | Admin Login rate limit | Max 5 logins/min/IP — triggers 1h block. Cache the Admin JWT and use RefreshToken on 401 — do not re-login |

---

## Error Response Envelope

All API errors follow this structure:

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

Always read `Errors[].Message` — it contains the actionable reason.

---

## Retry Policy

| Scenario | Recommended action |
|---|---|
| `401` on any request | Refresh token once; if refresh also 401 — re-login |
| `429` on Admin Login | Rate limit: 5 requests/min → 1-hour block per IP. Use cached `RefreshToken` if available; if no token yet (cold start) — wait 1 hour or use a different IP. Do not retry Login. |
| `5xx` | Retry with exponential backoff (2s, 4s, 8s); max 3 attempts |
| `422` | Do not retry — fix the constraint first (e.g. delete users before deleting instance) |

---

## Idempotency Notes

- `DELETE` endpoints: calling delete on an already-deleted entity returns `403` or `404` (Accounts API) / `200 Result: null` — treat as success.
- `PATCH` endpoints: safe to retry; re-applying same values has no side effect.
- `POST` create endpoints: **not idempotent** — calling twice creates a duplicate. Check existence with GET before creating.
