# Flutter Plugin API Reference

This reference summarizes the Dart API shape verified from `telematics_sdk` plugin version `1.2.0`, with native SDK checkpoints iOS `7.2.0` and Android `4.1.0`. Inspect the latest package and installed package before editing an app because method names and platform support can change.

## Dependency

Before editing `pubspec.yaml`, verify the latest package version:

```bash
curl -s https://pub.dev/api/packages/telematics_sdk
```

Read `latest.version`, or let Flutter resolve the latest compatible package:

```bash
flutter pub add telematics_sdk
```

If editing `pubspec.yaml` manually, use the latest compatible version rather than the example version from this reference:

```yaml
dependencies:
  telematics_sdk: ^<latest-pub-version>
```

When the user asks for the repository version:

```bash
git ls-remote --tags --refs https://github.com/Mobile-Telematics/telematicsSDK-demoapp-flutter-.git
```

Use the latest semantic version tag exactly:

```yaml
dependencies:
  telematics_sdk:
    git:
      url: https://github.com/Mobile-Telematics/telematicsSDK-demoapp-flutter-.git
      ref: <latest-semver-tag>
```

Run `flutter pub get` after editing `pubspec.yaml`.

## Entry Point

Import and create the API:

```dart
import 'package:telematics_sdk/telematics_sdk.dart';

final trackingApi = TrackingApi();
```

No app-side credentials are passed to `TrackingApi()`. The SDK setup described by this skill does not require an API key or project credential in Dart code.

Prefer wrapping this in an app service:

```dart
class TelematicsService {
  TelematicsService({TrackingApi? trackingApi})
      : _trackingApi = trackingApi ?? TrackingApi();

  final TrackingApi _trackingApi;
}
```

Do not scatter `TrackingApi()` calls across many widgets. Centralizing the API keeps permission checks, device ID setup, and tracking flow state consistent.

## Common Methods

- `isInitialized() -> Future<bool?>`
- `setDeviceID({required String deviceId})`
- `getDeviceId() -> Future<String?>`
- `getDeviceIdRegistrationState() -> Future<DeviceIdRegistrationState>`
- `logout()`
- `isAllRequiredPermissionsAndSensorsGranted() -> Future<bool?>`
- `isSdkEnabled() -> Future<bool?>`
- `isTracking() -> Future<bool?>`
- `setEnableSdk({required bool enable})`
- `getTrackingState() -> Future<TrackingState>`
- `startManualTracking() -> Future<bool?>`
- `startTrackAsPersistent() -> Future<bool?>`
- `stopManualTracking() -> Future<bool?>`
- `setMaxPersistentTrackingInterval({required int minutes})`
- `getMaxPersistentTrackingInterval() -> Future<int?>`
- `setTrackingMode({required TrackingMode trackingMode})`
- `getTrackingMode() -> Future<TrackingMode?>`
- `uploadUnsentTrips()`
- `getUnsentTripCount() -> Future<int?>`
- `sendCustomHeartbeats({required String reason})`
- `showPermissionWizard({AndroidPermissionWizardOptions? android}) -> Future<void>`
- `setProperties({required Map<String, String> properties})`
- `getProperties() -> Future<Map<String, String>>`
- `clearProperties()`
- `setSubUnits({required Map<String, String> subUnits})`
- `getSubUnits() -> Future<Map<String, String>>`
- `clearSubUnits()`
- `addActivityLog({required String text, required Map<String, String> data})`
- `registerSpeedViolations({required double speedLimitKmH, required int speedLimitTimeout})`
- `setAccidentDetectionSensitivity({required AccidentDetectionSensitivity sensitivity})`
- `setAccidentDetectionEnabled({required bool value})`
- `isAccidentDetectionEnabled() -> Future<bool?>`
- `isRTLDEnabled() -> Future<bool?>`

## Platform-Specific Methods

iOS-only:

- `getApiLanguage()`
- `setApiLanguage({required ApiLanguage language})`
- `isAggressiveHeartbeats()`
- `setAggressiveHeartbeats({required bool value})`
- `setDisableTracking({required bool value})`
- `isDisableTracking()`
- `isWrongAccuracyState()`
- `requestIOSLocationAlwaysPermission()`
- `requestIOSMotionPermission()`
- `configureIosPermissionWizard(IosPermissionWizardConfiguration configuration)`
- `configureIosMissingPermissionsAlert(IosMissingPermissionsAlertConfiguration configuration)`
- `setIosMissingPermissionsAlertEnabled(bool enabled)`
- `iOSWrongAccuracyAuthorization`
- `iOSRTLDDataCollected`

Android-only:

- `setAndroidAutoStartEnabled({required bool enable, required bool permanent})`
- `isAndroidAutoStartEnabled()`

The plugin throws `UnsupportedError` for wrong-platform calls. Guard platform-specific calls with `Platform.isIOS` or `Platform.isAndroid`.

## Streams

The plugin exposes native callbacks as streams:

- `onPermissionWizardClose -> Stream<PermissionWizardResult>`
- `lowPowerMode -> Stream<bool>`
- `locationChanged -> Stream<TrackLocation>`
- `trackingStateChanged -> Stream<bool>`
- `speedViolation -> Stream<SpeedViolation>`
- `iOSWrongAccuracyAuthorization -> Stream<void>`
- `iOSRTLDDataCollected -> Stream<void>`
- `futureTrackTagAdded -> Stream<FutureTrackTagAddResult>`
- `futureTrackTagRemoved -> Stream<FutureTrackTagRemoveResult>`
- `allFutureTrackTagsRemoved -> Stream<FutureTrackTagsRemoveResult>`
- `futureTrackTagsReceived -> Stream<FutureTrackTagsResult>`

Cancel subscriptions in `dispose` or service shutdown:

```dart
late final StreamSubscription<bool> _trackingSub;

void start() {
  _trackingSub = _trackingApi.trackingStateChanged.listen((isTracking) {
    // Update app state.
  });
}

Future<void> dispose() => _trackingSub.cancel();
```

## Permissions Wizard

The two-boolean wizard overload was removed. On Android, configure the SDK 4.1 wizard at launch:

```dart
await trackingApi.showPermissionWizard(
  android: const AndroidPermissionWizardOptions(
    themeMode: AndroidPermissionWizardThemeMode.system,
    blockEarlyExit: false,
    skipWizardPages: false,
  ),
);
```

`blockEarlyExit` prevents leaving before the wizard completes. `skipWizardPages` skips informational pages. `showPermissionWizard` completes after presentation begins; wait for `onPermissionWizardClose` before enabling a permission-dependent product flow.

On iOS, the Android options are ignored. Configure the iOS 7.2 guided wizard and optional independent foreground alert before launching:

```dart
if (Platform.isIOS) {
  await trackingApi.configureIosPermissionWizard(
    const IosPermissionWizardConfiguration(),
  );
  await trackingApi.configureIosMissingPermissionsAlert(
    const IosMissingPermissionsAlertConfiguration(isBlocking: false),
  );
  await trackingApi.setIosMissingPermissionsAlertEnabled(true);
}
await trackingApi.showPermissionWizard();
```

Omitted iOS configuration fields retain native defaults. The guided wizard configures Location When In Use, Location Always, Motion & Fitness, status copy, and light/dark themes. The missing-permissions alert is independent; enable it only when the product needs reminders after permissions have already been requested.

## Flow Sequences

Supported app-level flows:

- automatic tracking
- standard manual tracking without future tags
- standard manual tracking with legacy Future Tags
- app-controlled persistent manual tracking without future tags
- app-controlled persistent manual tracking with legacy Future Tags
- one-time persistent manual tracking without future tags
- one-time persistent manual tracking with legacy Future Tags

For Flutter tagged-flow snippets, `addFutureTrackTag(...)` means an app facade helper that calls the raw plugin `TrackingApi.addFutureTrackTag(...)` and completes only after `futureTrackTagAdded` emits the native result. If the app uses the raw plugin method directly, start listening to `futureTrackTagAdded` before the call and await the result before starting tracking when tag attachment is product-critical.

Device identity setup:

```dart
await trackingApi.setDeviceID(deviceId: deviceId);
```

Set the device ID from the app's login/session binding flow before enabling automatic SDK collection or starting manual tracking. The value is a Damoov platform user identifier in GUID format, also known as DeviceToken. One DeviceToken per app user. Obtain it via `POST https://user.telematicssdk.com/v1/Registration/create` (InstanceId + InstanceKey headers): omit CustomToken to let Damoov generate a UUID, or pass CustomToken to register your own UUID. Store it in the app's backend database. Do not use a locally generated UUID without registering it on the Damoov platform first. Do not repeat this call inside every tracking start method.

Automatic tracking:

```dart
await trackingApi.setEnableSdk(enable: true);
```

Automatic tracking stop:

```dart
await trackingApi.setEnableSdk(enable: false);
```

Disable SDK collection while preserving device ID:

```dart
await trackingApi.setEnableSdk(enable: false);
```

Logout when clearing identity is intended:

```dart
await trackingApi.logout();
```

`logout()` clears the device ID. Set the device ID again before enabling the SDK or starting tracking later.

Standard manual tracking:

```dart
await trackingApi.setEnableSdk(enable: true);
await trackingApi.setTrackingMode(trackingMode: TrackingMode.standard);
await trackingApi.startManualTracking();
```

Calling `startManualTracking()` or `startTrackAsPersistent()` while tracking is already active is idempotent: the SDK continues the existing track and does not start a new one. A facade may still check `isTracking()` to keep UI state clear.

Standard manual stop without future tags:

```dart
await trackingApi.stopManualTracking();
await trackingApi.setEnableSdk(enable: false);
```

Standard manual tracking with future tags:

```dart
await trackingApi.setEnableSdk(enable: true);
await trackingApi.setTrackingMode(trackingMode: TrackingMode.standard);
await addFutureTrackTag(tag: tag, source: source);
await trackingApi.startManualTracking();
```

Standard manual stop with future-tag cleanup:

```dart
await trackingApi.removeAllFutureTrackTags();
await trackingApi.stopManualTracking();
await trackingApi.setEnableSdk(enable: false);
```

App-controlled persistent manual tracking:

```dart
await trackingApi.setEnableSdk(enable: true);
await trackingApi.setMaxPersistentTrackingInterval(minutes: minutes);
await trackingApi.setTrackingMode(trackingMode: TrackingMode.persistent);
await trackingApi.startManualTracking();
```

App-controlled persistent stop without future tags:

```dart
await trackingApi.stopManualTracking();
await trackingApi.setTrackingMode(trackingMode: TrackingMode.standard);
await trackingApi.setEnableSdk(enable: false);
```

App-controlled persistent manual tracking with future tags:

```dart
await trackingApi.setEnableSdk(enable: true);
await trackingApi.setMaxPersistentTrackingInterval(minutes: minutes);
await trackingApi.setTrackingMode(trackingMode: TrackingMode.persistent);
await addFutureTrackTag(tag: tag, source: source);
await trackingApi.startManualTracking();
```

App-controlled persistent stop with future-tag cleanup:

```dart
await trackingApi.removeAllFutureTrackTags();
await trackingApi.stopManualTracking();
await trackingApi.setTrackingMode(trackingMode: TrackingMode.standard);
await trackingApi.setEnableSdk(enable: false);
```

Always restore `TrackingMode.standard` after app-controlled persistent flows unless the product explicitly wants future automatic sessions to remain persistent.

One-time persistent manual tracking:

```dart
await trackingApi.setEnableSdk(enable: true);
await trackingApi.setMaxPersistentTrackingInterval(minutes: minutes);
await trackingApi.startTrackAsPersistent();
```

One-time persistent stop without future tags:

```dart
await trackingApi.stopManualTracking();
await trackingApi.setEnableSdk(enable: false);
```

One-time persistent manual tracking with future tags:

```dart
await trackingApi.setEnableSdk(enable: true);
await trackingApi.setMaxPersistentTrackingInterval(minutes: minutes);
await addFutureTrackTag(tag: tag, source: source);
await trackingApi.startTrackAsPersistent();
```

One-time persistent stop with future-tag cleanup:

```dart
await trackingApi.removeAllFutureTrackTags();
await trackingApi.stopManualTracking();
await trackingApi.setEnableSdk(enable: false);
```

Do not call `setTrackingMode(trackingMode: TrackingMode.persistent)` before `startTrackAsPersistent()`, and do not manually restore `TrackingMode.standard` after stopping a one-time persistent session unless the installed native API proves the bridge does not follow native SDK behavior.

If the app intentionally combines manual trips with automatic tracking, keep the SDK enabled after `stopManualTracking()` and document that product behavior in the facade.

## Trip Metadata

Use Properties for trip metadata and Sub-units for analytical classification. Both are flat string maps; do not include personally identifiable information.

```dart
await trackingApi.setProperties(properties: {'order': 'A-42'});
final properties = await trackingApi.getProperties();
await trackingApi.clearProperties();

await trackingApi.setSubUnits(subUnits: {'vehicle': 'van-7'});
final subUnits = await trackingApi.getSubUnits();
await trackingApi.clearSubUnits();

await trackingApi.addActivityLog(
  text: 'Arrived at depot',
  data: const {},
);
```

- Both setters replace the complete map. Read first before changing one key; never pass an empty map to clear it.
- Properties allow 1–20 entries. A change during active tracking completes the current trip and starts the next trip with the replacement.
- Sub-units allow 1–5 entries. Changes never restart active tracking and apply to the next trip.
- Keys and values must be non-empty and no longer than 255 characters. Both maps clear on logout or device-ID change.
- Activity Log requires active tracking. It neither stops nor splits tracking; text must be 1–1000 characters, a trip allows 100 entries, and an empty data map is valid.

## Deprecated Future Tags

Future Tags remain for backwards compatibility. Use Properties or Sub-units for all new trip-metadata work.

Future tag operations return immediately and deliver results through streams on `TrackingApi`. Start listening before invoking the operation so a fast native result cannot be missed:

```dart
final trackingApi = TrackingApi();
final addResultFuture = trackingApi.futureTrackTagAdded.firstWhere(
  (result) => result.tag.tag == 'business',
);

await trackingApi.addFutureTrackTag(tag: 'business');
final addResult = await addResultFuture;
```

The raw plugin contract is `addFutureTrackTag({required String tag, String? source})`: `tag` is required and `source` is optional/nullable. Both values are product-defined; the SDK does not define an enum or SDK-side value restrictions. Use `tag` for the business label and `source` for the app module or user action that created it. Omit `source` when it is unavailable; do not pass an invented empty string.

When the facade exposes `addFutureTrackTag(...)`, await `futureTrackTagAdded` and return the SDK-provided `FutureTrackTagAddResult`. Create the stream wait before calling the raw method:

```dart
Future<FutureTrackTagAddResult> addFutureTrackTag({
  required String tag,
  String? source,
}) async {
  final resultFuture = _trackingApi.futureTrackTagAdded.firstWhere(
    (result) => result.tag.tag == tag,
  );

  await _trackingApi.addFutureTrackTag(tag: tag, source: source);
  return resultFuture;
}
```

Apply the same stream-first sequence to remove, remove-all, and get operations using their corresponding Future Tag result streams.

Available methods:

- `getFutureTrackTags()`
- `addFutureTrackTag({required String tag, String? source})`
- `removeFutureTrackTag({required String tag, String? source})`
- `removeAllFutureTrackTags()`

For a manually tagged trip, add the future tag and wait for the `futureTrackTagAdded` result before starting tracking where product correctness depends on tags being attached to the upcoming trip.

The verified Flutter wrapper exposes future-tag operations for upcoming trips. It does not expose a processed-trip tag editing API in the checked plugin surface. If a product needs post-trip tag editing, inspect the latest installed plugin first and add/verify a native bridge before claiming support.

## Recommended Service Shape

Expose app-level flows rather than raw plugin calls from widgets:

```dart
enum TelematicsFlow {
  automatic,
  standardManual,
  standardManualWithFutureTag,
  appControlledPersistentManual,
  appControlledPersistentManualWithFutureTag,
  oneTimePersistentManual,
  oneTimePersistentManualWithFutureTag,
}
```

Recommended facade method pairs:

```dart
Future<void> enableAutomaticTracking();
Future<void> disableAutomaticTracking();
Future<void> startStandardManualTracking();
Future<void> stopStandardManualTracking();
Future<void> startStandardManualTrackingWithFutureTag({required String tag, String? source});
Future<void> stopStandardManualTrackingWithFutureTag();
Future<void> startPersistentManualTracking({required int minutes});
Future<void> stopPersistentManualTracking();
Future<void> startPersistentManualTrackingWithFutureTag({required String tag, required int minutes, String? source});
Future<void> stopPersistentManualTrackingWithFutureTag();
Future<void> startOneTimePersistentManualTracking({required int minutes});
Future<void> stopOneTimePersistentManualTracking();
Future<void> startOneTimePersistentManualTrackingWithFutureTag({required String tag, required int minutes, String? source});
Future<void> stopOneTimePersistentManualTrackingWithFutureTag();
```

The service should:

- Expose a separate identity method that validates and sets a non-empty device ID.
- Expose `logout()` separately for user logout/account-removal semantics.
- Check permissions before enable/start flows.
- Expose flow-specific stop methods instead of one shared manual stop that infers the current mode from hidden state.
- Sequence future tag calls before manual starts.
- Convert `PlatformException` and `UnsupportedError` into app-facing errors.
- Keep platform-specific controls behind platform checks.

## Testing Notes

iOS Simulator and Android Emulator can exercise integration flow, permissions, and trip
recording — but only if a location feed is active. **By default both emit no movement**, so
without enabling simulation the SDK records no trip (`ActivityStatus` stays `"No Data"` and
no trip appears in Datahub).

- iOS Simulator: menu **Features → Location → Freeway Drive**, or play an interpolated route
  with `xcrun simctl location booted start --speed=25 37.3324,-122.0332 37.3639,-122.0450 37.3939,-122.0800 37.4139,-122.1100`.
- Android Emulator: generate a route as a series of `adb emu geo fix <lon> <lat>` calls
  spaced ~2s apart, or use Extended controls → **Location** → load a GPX/KML route →
  **Play Route**.
- If `simctl` / `adb` reports no booted device, ask the developer to boot the device and
  pick a preset / replay a route.

HF Data (accelerometer/gyroscope) cannot be fully tested on emulators; run final background
and sensor-heavy validation on real devices.
