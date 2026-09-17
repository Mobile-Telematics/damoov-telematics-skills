# React Native Plugin API Reference

This reference summarizes the TypeScript API shape verified from the public `react-native-telematics` source at version `3.1.2`, with native SDK checkpoints iOS `7.2.0` and Android `4.1.0`. Version `3.1.2` declares `react-native >=0.83.0` and is verified on React Native `0.83.10` (Expo SDK 55), `0.85.3` (Expo SDK 56), and `0.86.3` (Expo SDK 57). Inspect the latest package and installed package before editing an app because method names and platform support can change.

The JS API is identical on both integration paths. For the native setup that has to exist underneath it, see `expo-config-plugin.md` for Expo CNG projects and `../android/host-setup.md` / `../ios/host-setup.md` for bare React Native.

## Dependency

Before editing `package.json`, verify the latest published package:

```bash
npm view react-native-telematics version
```

Use the app's package manager to install the latest compatible version:

```bash
yarn add react-native-telematics@latest
```

or:

```bash
npm install react-native-telematics@latest
```

When the user asks for the repository version:

```bash
git ls-remote --tags --refs https://github.com/Mobile-Telematics/telematicsSDK-demoapp-react.git
```

Use the latest semantic version tag exactly:

```json
{
  "dependencies": {
    "react-native-telematics": "github:Mobile-Telematics/telematicsSDK-demoapp-react#<latest-semver-tag>"
  }
}
```

Run the app-standard install command and rebuild native apps after adding the package. On an Expo CNG project, re-run `npx expo prebuild --clean` instead of editing native files. Do not bypass the `react-native >=0.83.0` peer constraint for version `3.1.2`; choose a plugin release compatible with an older React Native app instead. The floor is real on iOS: the podspec needs the `spm_dependency` helper that React Native `0.83` introduced, and `pod install` fails without it.

`@expo/config-plugins` is an optional peer dependency, used only by the Expo config plugin. Bare React Native apps do not need it.

## Entry Point

Import the default API and needed enums/listeners:

```ts
import { Platform } from 'react-native';
import TelematicsSdk, {
  AccidentDetectionSensitivity,
  ApiLanguage,
  TrackingMode,
  addOnLocationChangedListener,
  addOnTrackingStateChangedListener,
  addOnLowPowerModeListener,
} from 'react-native-telematics';
```

The package exposes its bridge through a TurboModule. React Native `0.82+` runs only on the New Architecture, including every version in the supported `0.83+` range; do not present a legacy module as a runtime fallback or set `newArchEnabled=false` as a workaround. If the module is missing, the JS wrapper throws an error that usually means pods/Gradle sync and a native rebuild are required. Verify the generated host build completes with the TurboModule enabled.

No app-side credentials are passed to the React Native plugin. The SDK setup described by this skill does not require API keys in JS, `Info.plist`, or `AndroidManifest.xml`.

## Common Methods

- `initializeSdk(): Promise<void>`
- `isInitializedSdk(): Promise<boolean>`
- `getDeviceId(): Promise<string>`
- `setDeviceId(deviceId: string): Promise<void>`
- `getDeviceIdRegistrationState(): Promise<DeviceIdRegistrationState>`
- `logout(): Promise<void>`
- `isAllRequiredPermissionsAndSensorsGranted(): Promise<boolean>`
- `isSdkEnabled(): Promise<boolean>`
- `isTracking(): Promise<boolean>`
- `setEnableSdk(enable: boolean): Promise<void>`
- `startManualTracking(): Promise<void>`
- `startTrackAsPersistent(): Promise<void>`
- `stopManualTracking(): Promise<void>`
- `setMaxPersistentTrackingInterval(minutes: number): Promise<void>`
- `getMaxPersistentTrackingInterval(): Promise<number>`
- `setTrackingMode(trackingMode: TrackingMode): Promise<void>`
- `getTrackingMode(): Promise<TrackingMode>`
- `getTrackingState(): Promise<TrackingState>`
- `uploadUnsentTrips(): Promise<void>`
- `getUnsentTripCount(): Promise<number>`
- `sendCustomHeartbeats(reason: string): Promise<void>`
- `showPermissionWizard(options?: AndroidPermissionWizardOptions): Promise<boolean>`
- `setProperties(properties: Record<string, string>): Promise<void>`
- `getProperties(): Promise<Record<string, string>>`
- `clearProperties(): Promise<void>`
- `setSubUnits(subUnits: Record<string, string>): Promise<void>`
- `getSubUnits(): Promise<Record<string, string>>`
- `clearSubUnits(): Promise<void>`
- `addActivityLog(text: string, data: Record<string, string>): Promise<void>`
- `registerSpeedViolations({ speedLimitKmH, speedLimitTimeout }): Promise<void>`
- `setAccidentDetectionSensitivity(accidentDetectionSensitivity): Promise<void>`
- `enableAccidents(enable: boolean): Promise<void>`
- `isEnabledAccidents(): Promise<boolean>`
- `isRTLDEnabled(): Promise<boolean>`

Accident detection naming:

- The verified RN plugin still exposes `enableAccidents(...)` and `isEnabledAccidents()`.
- Native iOS/Android SDK implementations use the newer names `setAccidentDetectionEnabled(...)` and `isAccidentDetectionEnabled()`.
- Do not generate calls to the new RN names until the installed plugin source exposes them. When updating the plugin itself, add the new names and mark the old RN methods deprecated.

Enums:

- `TrackingMode.Standard = 0`
- `TrackingMode.Persistent = 1`
- `AccidentDetectionSensitivity.Normal = 0`
- `AccidentDetectionSensitivity.Sensitive = 1`
- `AccidentDetectionSensitivity.Tough = 2`
- `ApiLanguage.none`, `english`, `russian`, `portuguese`, `spanish`

## Platform-Specific Methods

iOS-only:

- `getApiLanguage()`
- `setApiLanguage(language: ApiLanguage)`
- `isAggressiveHeartbeats()`
- `setAggressiveHeartbeats(enable: boolean)`
- `setDisableTracking(value: boolean)`
- `isDisableTracking()`
- `isWrongAccuracyState()`
- `requestIOSLocationAlwaysPermission()`
- `requestIOSMotionPermission()`
- `configureIosPermissionWizard(configuration: IosPermissionWizardConfiguration)`
- `configureIosMissingPermissionsAlert(configuration: IosMissingPermissionsAlertConfiguration)`
- `setIosMissingPermissionsAlertEnabled(enabled: boolean)`
- `addOnLowPowerModeListener(...)`
- `addOnWrongAccuracyAuthorizationListener(...)`
- `addOnRtldColectedData(...)`

Android-only:

- `setAndroidAutoStartEnabled({ enable: boolean, permanent: boolean })`
- `isAndroidAutoStartEnabled()`

The native side rejects wrong-platform calls. Guard platform-specific calls with `Platform.OS`.

## Listeners

All listeners return subscriptions with `.remove()`:

- `addOnLowPowerModeListener(({ enabled }) => void)` iOS only
- `addOnLocationChangedListener(({ latitude, longitude }) => void)`
- `addOnTrackingStateChangedListener((state: boolean) => void)`
- `addOnWrongAccuracyAuthorizationListener(() => void)` iOS only
- `addOnRtldColectedData(() => void)` iOS only
- `addOnSpeedViolationListener((event) => void)`

Example:

```ts
useEffect(() => {
  const subs = [
    addOnLocationChangedListener(({ latitude, longitude }) => {
      // Update app state.
    }),
    addOnTrackingStateChangedListener((isTracking) => {
      // Update app state.
    }),
  ];

  if (Platform.OS === 'ios') {
    subs.push(addOnLowPowerModeListener(({ enabled }) => {}));
  }

  return () => subs.forEach((subscription) => subscription.remove());
}, []);
```

## Permissions Wizard

The two-boolean wizard overload was removed. On Android, configure the SDK 4.1 wizard at launch:

```ts
await TelematicsSdk.showPermissionWizard({
  themeMode: 'system',
  blockEarlyExit: false,
  skipWizardPages: false,
});
```

`blockEarlyExit` prevents leaving before the wizard completes. `skipWizardPages` skips informational pages. The promise resolves `true` only when all required permissions and sensors are available.

On iOS, those Android options are ignored. Configure the iOS 7.2 guided wizard and optional independent foreground alert before launching:

```ts
if (Platform.OS === 'ios') {
  await TelematicsSdk.configureIosPermissionWizard({});
  await TelematicsSdk.configureIosMissingPermissionsAlert({
    isBlocking: false,
  });
  await TelematicsSdk.setIosMissingPermissionsAlertEnabled(true);
}
await TelematicsSdk.showPermissionWizard();
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

Initialize once during app startup before JS-side API usage:

```ts
await TelematicsSdk.initializeSdk();
```

Do not call `initializeSdk()` from each tracking start method.

Per-platform semantics in `3.1.2`:

- **Android** — `initializeSdk()` performs the actual SDK initialization. Call it before any other API.
- **iOS** — the authoritative initialization is native: `RPEntry.initializeSDK()` in the AppDelegate. `initializeSdk()` also initializes the SDK when it has not been initialized yet, as a safety net for JS call ordering, but it does not remove the need for the AppDelegate call. Lifecycle forwards run at launch before any JS executes, so an app relying on the JS call alone still crashes at launch.

Every other iOS bridge method rejects with error code `SDK_NOT_INITIALIZED` until initialization has happened. Surface that code as a setup error; do not retry it as if it were transient. Check state first when diagnosing:

```ts
const initialized = await TelematicsSdk.isInitializedSdk();
```

`isInitializedSdk()` is the one method that is safe to call before initialization.

Device identity setup:

```ts
await TelematicsSdk.setDeviceId(deviceId);
```

Set the device ID from the app's login/session binding flow before enabling automatic SDK collection or starting manual tracking. Do not repeat this call inside every tracking start method.

The device ID is a Damoov platform user identifier in GUID format, also known as DeviceToken. One DeviceToken per app user. Obtain it via `POST https://user.telematicssdk.com/v1/Registration/create` (InstanceId + InstanceKey headers): omit CustomToken to let Damoov generate a UUID, or pass CustomToken to register your own UUID. Store it in the app's backend database. Do not use a locally generated UUID without registering it on the Damoov platform first.

Automatic tracking:

```ts
await TelematicsSdk.setEnableSdk(true);
```

Automatic tracking stop:

```ts
await TelematicsSdk.setEnableSdk(false);
```

Disable SDK collection while preserving device ID:

```ts
await TelematicsSdk.setEnableSdk(false);
```

Logout when clearing identity is intended:

```ts
await TelematicsSdk.logout();
```

`logout()` clears the device ID. Set the device ID again before enabling the SDK or starting tracking later.

Standard manual tracking:

```ts
await TelematicsSdk.setEnableSdk(true);
await TelematicsSdk.setTrackingMode(TrackingMode.Standard);
await TelematicsSdk.startManualTracking();
```

Calling `startManualTracking()` or `startTrackAsPersistent()` while tracking is already active is idempotent: the SDK continues the existing track and does not start a new one. A facade may still check `isTracking()` to keep UI state clear.

Standard manual stop without future tags:

```ts
await TelematicsSdk.stopManualTracking();
await TelematicsSdk.setEnableSdk(false);
```

Standard manual tracking with future tags:

```ts
await TelematicsSdk.setEnableSdk(true);
await TelematicsSdk.setTrackingMode(TrackingMode.Standard);
await TelematicsSdk.addFutureTrackTag(tag, source);
await TelematicsSdk.startManualTracking();
```

Standard manual stop with future-tag cleanup:

```ts
await TelematicsSdk.removeAllFutureTrackTags();
await TelematicsSdk.stopManualTracking();
await TelematicsSdk.setEnableSdk(false);
```

App-controlled persistent manual tracking:

```ts
await TelematicsSdk.setEnableSdk(true);
await TelematicsSdk.setMaxPersistentTrackingInterval(minutes);
await TelematicsSdk.setTrackingMode(TrackingMode.Persistent);
await TelematicsSdk.startManualTracking();
```

App-controlled persistent stop without future tags:

```ts
await TelematicsSdk.stopManualTracking();
await TelematicsSdk.setTrackingMode(TrackingMode.Standard);
await TelematicsSdk.setEnableSdk(false);
```

App-controlled persistent manual tracking with future tags:

```ts
await TelematicsSdk.setEnableSdk(true);
await TelematicsSdk.setMaxPersistentTrackingInterval(minutes);
await TelematicsSdk.setTrackingMode(TrackingMode.Persistent);
await TelematicsSdk.addFutureTrackTag(tag, source);
await TelematicsSdk.startManualTracking();
```

App-controlled persistent stop with future-tag cleanup:

```ts
await TelematicsSdk.removeAllFutureTrackTags();
await TelematicsSdk.stopManualTracking();
await TelematicsSdk.setTrackingMode(TrackingMode.Standard);
await TelematicsSdk.setEnableSdk(false);
```

Always restore `TrackingMode.Standard` after app-controlled persistent flows unless the product explicitly wants future automatic sessions to remain persistent.

One-time persistent manual tracking:

```ts
await TelematicsSdk.setEnableSdk(true);
await TelematicsSdk.setMaxPersistentTrackingInterval(minutes);
await TelematicsSdk.startTrackAsPersistent();
```

One-time persistent stop without future tags:

```ts
await TelematicsSdk.stopManualTracking();
await TelematicsSdk.setEnableSdk(false);
```

One-time persistent manual tracking with future tags:

```ts
await TelematicsSdk.setEnableSdk(true);
await TelematicsSdk.setMaxPersistentTrackingInterval(minutes);
await TelematicsSdk.addFutureTrackTag(tag, source);
await TelematicsSdk.startTrackAsPersistent();
```

One-time persistent stop with future-tag cleanup:

```ts
await TelematicsSdk.removeAllFutureTrackTags();
await TelematicsSdk.stopManualTracking();
await TelematicsSdk.setEnableSdk(false);
```

Do not call `setTrackingMode(TrackingMode.Persistent)` before `startTrackAsPersistent()`, and do not manually restore `TrackingMode.Standard` after stopping a one-time persistent session unless the installed native API proves the bridge does not follow native SDK behavior.

If the app intentionally combines manual trips with automatic tracking, keep the SDK enabled after `stopManualTracking()` and document that product behavior in the facade.

## Trip Metadata

Use Properties for trip metadata and Sub-units for analytical classification. Both are flat string records; do not include personally identifiable information.

```ts
await TelematicsSdk.setProperties({order: 'A-42'});
const properties = await TelematicsSdk.getProperties();
await TelematicsSdk.clearProperties();

await TelematicsSdk.setSubUnits({vehicle: 'van-7'});
const subUnits = await TelematicsSdk.getSubUnits();
await TelematicsSdk.clearSubUnits();

await TelematicsSdk.addActivityLog('Arrived at depot', {});
```

- Both setters replace the complete record. Read first before changing one key; never pass `{}` to clear it.
- Properties allow 1–20 entries. A change during active tracking completes the current trip and starts the next trip with the replacement.
- Sub-units allow 1–5 entries. Changes never restart active tracking and apply to the next trip.
- Keys and values must be non-empty and no longer than 255 characters. Both records clear on logout or device-ID change.
- Activity Log requires active tracking. It neither stops nor splits tracking; text must be 1–1000 characters, a trip allows 100 entries, and `{}` is valid when no event metadata is needed.

## Deprecated Future Tags

Future Tags remain for backwards compatibility. Use Properties or Sub-units for all new trip-metadata work.

Future tag operations are promise-based in the React Native wrapper:

```ts
const result = await TelematicsSdk.addFutureTrackTag('business');
```

The raw plugin contract is `addFutureTrackTag(tag: string, source?: string)`: `tag` is required and `source` is optional. Both values are product-defined; the SDK does not define an enum or SDK-side value restrictions. Use `tag` for the business label and `source` for the app module or user action that created it. Omit `source` when it is unavailable; do not pass an invented empty string or explicit `undefined` placeholder.

Available methods:

- `getFutureTrackTags() -> Promise<{ status: string; tags: Tag[] }>`
- `addFutureTrackTag(tag: string, source?: string) -> Promise<{ status: string; tag: Tag }>`
- `removeFutureTrackTag(tag: string, source?: string) -> Promise<{ status: string; tag: Tag }>`
- `removeAllFutureTrackTags() -> Promise<string>`

For a manually tagged trip, await the tag promise before starting tracking where product correctness depends on tags being attached to the upcoming trip.

The verified React Native wrapper exposes future-tag operations for upcoming trips. It does not expose a processed-trip tag editing API in the checked plugin surface. If a product needs post-trip tag editing, inspect the latest installed plugin first and add/verify a native bridge before claiming support.

## Recommended Service Shape

Expose app-level flows rather than raw plugin calls from components:

```ts
export type TelematicsFlow =
  | 'automatic'
  | 'standardManual'
  | 'standardManualWithFutureTag'
  | 'appControlledPersistentManual'
  | 'appControlledPersistentManualWithFutureTag'
  | 'oneTimePersistentManual'
  | 'oneTimePersistentManualWithFutureTag';
```

Recommended facade method pairs:

```ts
enableAutomaticTracking(): Promise<void>;
disableAutomaticTracking(): Promise<void>;
startStandardManualTracking(): Promise<void>;
stopStandardManualTracking(): Promise<void>;
startStandardManualTrackingWithFutureTag(tag: string, source?: string): Promise<void>;
stopStandardManualTrackingWithFutureTag(): Promise<void>;
startPersistentManualTracking(minutes: number): Promise<void>;
stopPersistentManualTracking(): Promise<void>;
startPersistentManualTrackingWithFutureTag(tag: string, minutes: number, source?: string): Promise<void>;
stopPersistentManualTrackingWithFutureTag(): Promise<void>;
startOneTimePersistentManualTracking(minutes: number): Promise<void>;
stopOneTimePersistentManualTracking(): Promise<void>;
startOneTimePersistentManualTrackingWithFutureTag(tag: string, minutes: number, source?: string): Promise<void>;
stopOneTimePersistentManualTrackingWithFutureTag(): Promise<void>;
```

The service should:

- Ensure `initializeSdk()` runs once at app startup, before the facade accepts tracking commands.
- Expose a separate identity method that validates and sets a non-empty device ID.
- Expose `logout()` separately for user logout/account-removal semantics.
- Check permissions before enable/start flows.
- Expose flow-specific stop methods instead of one shared manual stop that infers the current mode from hidden state.
- Sequence future tag calls before manual starts.
- Convert promise rejections into app-facing errors.
- Keep platform-specific controls behind `Platform.OS` checks.

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
