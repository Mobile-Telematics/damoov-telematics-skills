---
name: damoov-integration-testing-skill
description: Use when creating a test Damoov SDK user (DeviceToken) to validate an integration. Covers three approaches: manual DataHub UI, direct InstanceId+InstanceKey, and JWT-driven hierarchy registration. Also covers verifying the DeviceToken works end-to-end.
---

# Damoov Integration Testing Skill

Use this skill to create a test DeviceToken (SDK user) and verify that it works.
This is the starting point for any new integration — mobile or backend — before moving to production flows.

---

## Never do this

- **Never** use a production Instance for test users. Create a dedicated test Instance or Application.
- **Never** call `POST /v1/Auth/Login` more than 5 times per minute from the same IP — triggers a 1-hour block. Use Refresh instead.
- **Never** pass the `AccessToken` from registration to the mobile SDK — the SDK only needs `DeviceToken`.
- **Never** test with a DeviceToken that was not registered through the Damoov platform.

---

## Choose an approach

| Situation | Use |
|---|---|
| Manual testing, no code, no credentials yet | **Approach A — DataHub UI** |
| You have `InstanceId` and `InstanceKey` | **Approach B — Direct Registration API** |
| You only have admin email + password | **Approach C — JWT → Hierarchy → Register** |

---

## Approach A — DataHub UI (manual, no code)

1. Open [Datahub](https://datahub.damoov.com) and log in.
2. Navigate to **Users** → **Add SDK User**.
3. Fill in optional fields (name, email, phone) or leave blank.
4. After creation, copy the `DeviceToken` visible in the user's profile row.
5. Use this DeviceToken in your mobile SDK: `setDeviceID(deviceToken)` (see `../../mobile/references/devicetoken-flow.md`).

**Good for:** onboarding validation, demo accounts, one-off manual QA.
**Not for:** automated testing or CI pipelines.

---

## Approach B — Direct Registration API (recommended for scripts and CI)

**Precondition:** you have `InstanceId` and `InstanceKey`.
To get them: Datahub → **Control Panel** → **Hierarchy Management** → expand Instance → ⋮ → Copy InstanceId / Copy InstanceKey.

```bash
curl --request POST \
     --url https://user.telematicssdk.com/v1/Registration/create \
     --header 'InstanceId: <InstanceId>' \
     --header 'InstanceKey: <InstanceKey>' \
     --header 'accept: application/json' \
     --header 'content-type: application/json' \
     --data '{
       "UserFields": { "ClientId": "client-id-001" },
       "CreateAccessToken": false
     }'
```

Response:
```json
{
  "Result": {
    "DeviceToken": "<uuid>",
    "AccessToken": { "Token": "...", "ExpiresIn": 432000 },
    "RefreshToken": "..."
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Extract:** `Result.DeviceToken` — this is your test user's identifier.

**If `Result.DeviceToken` is absent or the response contains no `Result`:**
- Verify `InstanceId` and `InstanceKey` are correct — copy from Datahub, do not type manually.
- Verify headers are named exactly `InstanceId` and `InstanceKey` (case-sensitive).
- Verify the `InstanceKey` belongs to the same Instance as the `InstanceId`.

Full request schema: `references/registration-api.md`.

---

## Approach C — JWT → Hierarchy → Register (agent-driven, no hardcoded credentials)

Use when: a coding agent is doing the full setup autonomously, or you need dynamic Instance routing.

### Step 1 — Get admin JWT

```bash
curl --request POST \
  --url 'https://user.telematicssdk.com/v1/Auth/Login' \
  --header 'content-type: application/json' \
  --data '{"LoginFields":"{\"email\":\"<admin-email>\"}","Password":"<admin-password>"}'
```

Store `Result.AccessToken.Token`. Cache it — lifetime 24 hours. **Do not call Login again** while it is valid.
See `references/admin-auth.md` for the full rate-limit rules and Refresh flow.

### Step 2 — Resolve InstanceId + InstanceKey

```bash
curl --request GET 'https://portal-apis.telematicssdk.com/auth/permissions' \
  --header 'Authorization: Bearer <admin-jwt>'
```

Parse the response to find which `instancesPermissions` / `appsPermissions` / `companiesPermissions`
array is non-empty, then call the Accounts API to get `Id` (InstanceId) and `Key` (InstanceKey).

**Required:** Read `../../backend/damoov-backend-registration-skill/references/hierarchy.md`
before completing this step — it contains the exact Accounts API curl commands for listing
Applications and Instances based on access scope.

**If multiple Instances are available:**
- List all Instances with their `InstanceName` and `InstanceId`.
- Ask the user: "Which Instance should the test DeviceToken be registered in?"
- Proceed only after the user confirms the target `InstanceId`.
- Do not auto-select the first Instance — wrong Instance means test data is invisible in the expected scope.

### Step 3 — Register test user

Same curl as Approach B, using the resolved InstanceId + InstanceKey.

**If `Result.DeviceToken` is absent or the response contains no `Result`:**
- Verify `InstanceId` and `InstanceKey` are correct — copied from the Accounts API response, not typed manually.
- Verify headers are named exactly `InstanceId` and `InstanceKey` (case-sensitive).
- Verify the `InstanceKey` belongs to the same Instance as the `InstanceId`.

---

## Verify the DeviceToken works

After creating a DeviceToken, verify it was registered correctly:

### Check via API (no mobile app needed)

```bash
curl -X GET \
  'https://user.telematicssdk.com/v1/Management/users/find?DeviceToken=<uuid>&IncludeAccountInfo=true' \
  -H 'Authorization: Bearer <admin-jwt>'
```

Expected: `Result` array with one entry containing `Status: "Active"`.

If `Result` is an empty array `[]` — the registration failed or the DeviceToken is wrong.

### Check via mobile SDK

**Precondition for emulator/simulator — feed GPS location.**
The SDK cannot record a trip on iOS Simulator or Android Emulator unless the device is
emitting location updates. Without this, trip detection never fires and `ActivityStatus`
stays `"No Data"` regardless of a correct integration.

- **iOS Simulator — Freeway Drive (or another preset):**
  - Prefer starting it automatically:
    ```bash
    # play an interpolated route on the booted simulator at ~25 m/s
    xcrun simctl location booted start --speed=25 37.3324,-122.0332 37.3639,-122.0450 37.3939,-122.0800 37.4139,-122.1100
    ```
  - If no booted device is detected (`Simctl: no devices` / `Unable to lookup device`), ask
    the developer to enable it manually: iOS Simulator menu bar → **Features → Location →
    Freeway Drive**.
- **Android Emulator — `geo fix` route (generated by the skill):**
  - The skill generates a short route as a series of `geo fix` points ~2s apart at driving
    speed; continue until the route is long enough for trip detection:
    ```bash
    adb emu geo fix -122.0332 37.3324
    sleep 2; adb emu geo fix -122.0450 37.3639
    sleep 2; adb emu geo fix -122.0800 37.3939
    sleep 2; adb emu geo fix -122.1100 37.4139
    ```
  - If no emulator is attached (`adb: no devices`), ask the developer to open Android
    Emulator → Extended controls → **Location**, load a GPX/KML route, and press
    **Play Route**.
- **Real device:** no location simulation needed; go drive.

Then:

1. Call `setDeviceID(deviceToken)` in your platform's SDK (see `../../mobile/references/devicetoken-flow.md`).
2. Enable the SDK and start a short test trip.
3. After ~5 minutes, query `GET /v1/Management/users/find?DeviceToken=<uuid>` again.
4. `ActivityStatus` should change from `"No Data"` to `"Active"`.

If `ActivityStatus` does **not** change from `"No Data"` and you are on an
emulator/simulator — confirm a location simulation is actually running (and that the route
is long enough and at driving speed) before assuming the integration is broken.

---

## References

- `references/registration-api.md` — POST /v1/Registration/create full schema, User Login, GetFilteredPage
- `references/admin-auth.md` — Admin JWT login, refresh, rate-limit rules
- `../../backend/damoov-backend-registration-skill/references/hierarchy.md` — Accounts API hierarchy resolution
- `../../mobile/references/devicetoken-flow.md` — Mobile SDK DeviceToken handoff
