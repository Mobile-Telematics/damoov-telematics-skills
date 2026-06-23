# Admin Auth — JWT Login and Refresh

Reference for obtaining and maintaining an admin-level JWT token.

---

## Admin credentials

Obtained from Datahub → **Control Panel** → **Admin Credentials** → **API Auth Credentials**.
These are separate from your Datahub web login credentials.

---

## Login — get JWT

```bash
curl --request POST \
  --url 'https://user.telematicssdk.com/v1/Auth/Login' \
  --header 'accept: application/json' \
  --header 'content-type: application/json' \
  --data '{"LoginFields":"{\"email\":\"<admin-email>\"}","Password":"<admin-password>"}'
```

Response:
```json
{
  "Result": {
    "AccessToken": {
      "Token": "<jwt>",
      "ExpiresIn": 86400
    },
    "RefreshToken": "<refresh-token>"
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

- `AccessToken.Token` — JWT, lifetime **86400 seconds (24 hours)**
- `RefreshToken` — valid for **3 months**

---

## CRITICAL: rate limit on Login

`POST /v1/Auth/Login` is rate-limited to **5 calls per minute per IP** — exceeding this
triggers a **1-hour block** on that IP.

Rules:
- **Cache the JWT** immediately after login. Store both `Token` and `RefreshToken`.
- **Never call Login again** while the cached JWT is still valid.
- On `401` response from any API → call RefreshToken (see below), NOT Login.
- Exceeding the limit returns `429 Too Many Requests`.

**On 429 from Login:**
- If you have a cached `RefreshToken` → call `POST /v1/Auth/RefreshToken` instead of Login.
- If you have no `RefreshToken` yet (cold start) → wait 1 hour, or make the
  initial Login from a different IP. Do not retry Login from the same IP.

---

## Refresh JWT

Call this when any API returns `401 Unauthorized`. Do NOT call Login.

```bash
curl --request POST \
  --url 'https://user.telematicssdk.com/v1/Auth/RefreshToken' \
  --header 'accept: application/json' \
  --header 'content-type: application/json' \
  --data '{
    "AccessToken": "<expired-jwt>",
    "RefreshToken": "<refresh-token>"
  }'
```

Response:
```json
{
  "Result": {
    "AccessToken": {
      "Token": "<new-jwt>",
      "ExpiresIn": 86400
    },
    "RefreshToken": "<new-refresh-token>"
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

Update your cache with both the new `Token` and the new `RefreshToken`.

---

## Token lifecycle summary

```
Login (once, or after refresh token expiry)
  → cache JWT (24h) + RefreshToken (3 months)
  → use JWT for all API calls
  → on 401 → RefreshToken → new JWT + new RefreshToken
  → after 3 months → Login again
```

---

## Same endpoint for user-level JWT

The same `POST /v1/Auth/Login` and `POST /v1/Auth/RefreshToken` endpoints are used for
user-level authentication. The difference is the payload:

- **Admin login**: `LoginFields` contains `email`, no `InstanceId` header
- **User login**: `LoginFields` contains `Devicetoken`, `InstanceId` header required,
  `Password` = InstanceKey

See `references/registration-api.md` for the user login example.
