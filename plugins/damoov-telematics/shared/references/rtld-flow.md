# RTD / RTLD Enable Flow

**RTD** (Real-Time Location Data) = Damoov platform service that streams live GPS position and
speed from the SDK to external systems while a trip is active.
**RTLD** (Real-Time Location Delegate / stream) = the SDK-side interface that receives RTD data.

---

## Three-level enable flow

All three levels must be configured before `isRTLDEnabled()` returns `true` on the device.

### Level 1 — Datahub: Enable RTD for the Application

⚠️ **Order unverified — requires Damoov support confirmation.**

In the Damoov Datahub UI, navigate to the Application settings and enable Real-Time Location Data.
This is a platform-level switch that gates RTD delivery for all users under the Application.

- Without Datahub configuration, `isRTLDEnabled()` returns `false` regardless of user flags or SDK state.
- Reference: https://docs.damoov.com/docs/real-time-location-tracker

### Level 2 — Backend: Set `EnableRealTimeLocation: true` for the user

```bash
curl --request PUT \
  --url 'https://user.telematicssdk.com/v1/Management/users/<DeviceToken>' \
  --header 'Authorization: Bearer <admin-jwt>' \
  --header 'Content-Type: application/json' \
  --data '{
    "UserFields": [
      {
        "EnableRealTimeLocation": true
      }
    ]
  }'
```

Full `PUT /v1/Management/users` curl and response:
`../../skills/damoov-user-management-skill/references/user-management-api.md` — "Update user" section.

### Level 3 — SDK: Register delegate / stream and verify

**iOS (Swift)**
```swift
// Assign delegate before tracking starts
sdk.rtldDelegate = self

// Delegate callback
func didReceiveRTLD(_ data: RPRTLDData) { ... }

// Check status
let enabled = sdk.isRTLDEnabled()
```

**Android (Kotlin)**
```kotlin
// RTD access via TelematicsRepository (or TrackingApi directly)
val isEnabled = telematicsRepository.isRTLDEnabled()
// Observe RTD data via SDK callback — check integration-reference.md for exact API
```

**Flutter (Dart)**
```dart
bool? enabled = await TrackingApi.isRTLDEnabled();
// iOS stream
TrackingApi.iOSRTLDDataCollected.listen((_) { ... });
```

**React Native (TypeScript)**
```typescript
const enabled = await TelematicsSdk.isRTLDEnabled();
// iOS listener
TelematicsSdk.addOnRtldColectedData(() => { ... });
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `isRTLDEnabled()` returns `false` | Datahub RTD not enabled | Enable at Application level in Datahub UI |
| `isRTLDEnabled()` returns `false` after Datahub enabled | `EnableRealTimeLocation` flag not set for this user | Call `PUT /v1/Management/users/{DeviceToken}` with `EnableRealTimeLocation: true` |
| Delegate/stream registered but no callbacks | Trip not active | RTD data is only streamed while a trip is in progress |
| Callbacks arrive on iOS but not Android | Android RTLD integration not wired | Check Android RTLD callback setup in `../../skills/android-telematics-sdk-integration-skill/references/android/integration-reference.md` |
