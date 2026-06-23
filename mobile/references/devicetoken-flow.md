# DeviceToken — Registration and Mobile Handoff Flow

This document describes the full lifecycle of a Damoov DeviceToken: how the backend
registers it, stores it, passes it to the mobile app, and how the mobile SDK consumes it.

**DeviceToken** is a UUID that uniquely identifies one Damoov SDK user. It is also referred
to as `UserId` or `DeviceId` in different parts of the platform — all three names refer to
the same value.

---

## Why the backend owns registration

The mobile SDK only needs the DeviceToken to operate. The backend must own registration
because:
- `InstanceKey` (the registration credential) is an instance-level secret. It must never
  be embedded in a mobile app binary or transmitted to the client.
- The backend can link `DeviceToken → internalUserId` in its own database and reuse the
  DeviceToken across sessions and devices.

---

## Full flow

```
Your Backend                    Mobile App                Damoov SDK
     |                               |                         |
     |  POST /v1/Registration/create |                         |
     |  InstanceId + InstanceKey     |                         |
     |  → Damoov Registration API    |                         |
     |                               |                         |
     |  ← { DeviceToken: "<uuid>" }  |                         |
     |                               |                         |
     |  Store in DB:                 |                         |
     |  internalUserId → DeviceToken |                         |
     |                               |                         |
     |  On user login response:      |                         |
     |  ─── DeviceToken ────────────>|                         |
     |  (e.g. in auth response body) |                         |
     |                               |                         |
     |                               |  setDeviceID(token)  -->|
     |                               |  (see platform note     |
     |                               |   below)                |
     |                               |                         |
     |                               |  SDK is ready to track  |
```

---

## Registration API call (backend)

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

Response: `Result.DeviceToken` is the UUID to store and later deliver to mobile.

For InstanceId + InstanceKey acquisition, and for the JWT-based dynamic hierarchy flow,
see `../../testing/damoov-integration-testing-skill/references/registration-api.md` and
`../../backend/damoov-backend-registration-skill/SKILL.md`.

---

## Passing DeviceToken to the mobile app

The mobile app must receive the DeviceToken from your backend — typically in the login
or session-init response. The mobile app must **not** generate or guess the DeviceToken
locally. Do not use a locally-generated UUID without first registering it on the Damoov platform.

---

## Platform-specific SDK initialization

### iOS — RPEntry

```swift
// After receiving DeviceToken from your backend login response:
try RPEntry.instance.setDeviceID(deviceId: deviceToken)
```

- Use `RPEntry.instance.setDeviceID(deviceId:)` — NOT `setDeviceToken`.
- `RPEntry.initializeSDK()` must be called first (in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`).
- `try` is required; handle `InvalidDeviceIdError` for malformed UUIDs.
- On logout: `RPEntry.instance.logout()` clears the device ID.

### Android — TrackingApi

```kotlin
// After receiving DeviceToken from your backend login response:
TrackingApi.getInstance().setDeviceID(deviceToken)
```

- Use `TrackingApi.getInstance().setDeviceID(deviceId)` — NOT `setDeviceToken`.
- `TrackingApi.getInstance()` must be initialized first (from `Application.onCreate()`).
- To clear on logout: `TrackingApi.getInstance().logout()` or `clearDeviceID()`.

### Flutter — TrackingApi

```dart
// After receiving DeviceToken from your backend login response:
await TrackingApi().setDeviceID(deviceId: deviceToken);
```

- Use `setDeviceID(deviceId: ...)` — NOT `setDeviceToken`.
- On logout: `TrackingApi().logout()`.

### React Native — TelematicsSdk

```typescript
// After receiving DeviceToken from your backend login response:
await TelematicsSdk.setDeviceId(deviceToken);
```

- Use `TelematicsSdk.setDeviceId(...)` — NOT `setDeviceToken`.
- `TelematicsSdk.initializeSdk()` must be called once at app startup before other APIs.
- On logout: `TelematicsSdk.logout()`.

---

## NEVER do this

- **Never** embed `InstanceKey` in a mobile app — it is a backend-only secret.
- **Never** call `setDeviceToken(...)` — this is a deprecated API across all platforms.
  The current method is `setDeviceID` / `setDeviceId` (see platform section above).
- **Never** use a locally generated UUID as DeviceToken without first registering it via
  `POST /v1/Registration/create` with `CustomToken` set to that UUID.
- **Never** pass `AccessToken` or `RefreshToken` to the SDK — it only needs `DeviceToken`.

---

## References

- Registration API details: `../../testing/damoov-integration-testing-skill/references/registration-api.md`
- Backend production flow + hierarchy: `../../backend/damoov-backend-registration-skill/SKILL.md`
- iOS SDK integration: `../ios-telematics-sdk-integration-skill/SKILL.md`
- Android SDK integration: `../android-telematics-sdk-integration-skill/SKILL.md`
- Flutter SDK integration: `../flutter-telematics-sdk-integration-skill/SKILL.md`
- React Native SDK integration: `../react-native-telematics-sdk-integration-skill/SKILL.md`
