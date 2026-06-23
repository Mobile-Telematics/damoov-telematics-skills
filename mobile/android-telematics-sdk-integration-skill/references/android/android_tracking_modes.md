# Android Tracking Modes

App-level operating modes that define when SDK collection or a manual trip starts and stops.
Do not confuse with SDK-level `TrackingMode` enum (`Standard` / `Persistent`), which controls
how the SDK tracks *after* a mode enables or starts tracking.

---

## Modes

| Mode | Description | SDK calls involved |
|---|---|---|
| **Automatic** | SDK tracks trips autonomously via motion detection. No user interaction required. | `enableAutomaticTracking()` |
| **Disabled** | SDK collection is fully off. User is logged in but tracking is suspended. | `disableAutomaticTracking()` + `setEnableSdk(false, ...)` |
| **Standard manual** | User starts/stops each trip manually. Standard (non-persistent) SDK session. | `startTracking()` / `stopTracking()` |
| **Standard manual + tags** | Same as standard manual, but future tags are attached to the trip for categorization. | `startTracking()` + `addFutureTrackTag(...)` |
| **App-controlled persistent manual** | User starts a persistent tracking session; app controls stop. Survives process restart. | `startTrackAsPersistent()` / `stopTracking()` |
| **App-controlled persistent + tags** | Persistent session with future tags. | `startTrackAsPersistent()` + `addFutureTrackTag(...)` |
| **One-time persistent manual** | Single persistent session that auto-stops after the trip ends. | `startOneTimePersistentManualTracking()` / `stopOneTimePersistentManualTracking()` |
| **One-time persistent + tags** | Same, with future tags. | same + `addFutureTrackTag(...)` |

---

## Use Cases (when domain layer is present)

When the app has a use-case layer, implement each mode as a use case orchestrating `TelematicsRepository`:

```
EnableAutomaticModeUseCase
EnableDisabledModeUseCase
PrepareOnDemandModeUseCase
StartOnDemandTripUseCase
StopOnDemandTripUseCase
SignOnShiftUseCase
SignOffShiftUseCase
SetTripRecordModeUseCase
GetTripRecordModeUseCase
LogoutUseCase
```

Use cases call `TelematicsRepository` methods only — never `TrackingApi` directly.

---

## SDK TrackingMode enum

Passed to `startTracking()` / `startTrackAsPersistent()`:

| Value | Behaviour |
|---|---|
| `TrackingMode.Standard` | Normal trip tracking session |
| `TrackingMode.Persistent` | Session survives app restart/kill; use for long trips or background-first apps |

Full code examples: `integration-reference.md` — "Tracking flows" section.

---

## Cross-platform TrackingMode casing (important)

`TrackingMode` enum casing differs by SDK:

| Platform | Standard | Persistent |
|---|---|---|
| Android (Kotlin) | `TrackingMode.Standard` | `TrackingMode.Persistent` |
| iOS (Swift) | `.standard` | `.persistent` |
| Flutter (Dart) | `TrackingMode.standard` | `TrackingMode.persistent` |
| React Native (TS) | `TrackingMode.Standard` | `TrackingMode.Persistent` |

Do not copy casing from one platform to another — it will fail to compile or produce a runtime error.
