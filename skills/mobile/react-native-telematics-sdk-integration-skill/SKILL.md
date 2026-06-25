---
name: react-native-telematics-sdk-integration-skill
description: Use when designing, integrating, migrating, reviewing, or debugging the Damoov SDK React Native plugin in React Native apps, especially npm/yarn setup, react-native-telematics API usage, old/new architecture and TurboModule behavior, Android Gradle/manifest/proguard setup, iOS Podfile/SPM/Info.plist/AppDelegate/SceneDelegate setup, lifecycle forwarding, permission wizard wiring, automatic/manual tracking flows, persistent tracking, future tags, platform-specific APIs, and validation against the public React Native plugin source.
---

# React Native Telematics SDK Integration

## Operating Rule

Treat the React Native plugin source and the target app's lockfiles as the source of truth. Public docs and README examples are baseline guidance; verify the plugin API from `src/TelematicsSdk.ts`, `src/index.tsx`, the native bridge code, and the installed package version before editing app code.

The reference plugin source used to build this skill is the public repository [Mobile-Telematics/telematicsSDK-demoapp-react](https://github.com/Mobile-Telematics/telematicsSDK-demoapp-react), verified at package source version `3.0.1`, with React Native `0.81.4`, Android native SDK `com.telematicssdk:tracking:4.0.0`, and iOS SPM SDK `7.1.0` in the podspec. Treat those as API reference checkpoints, not install targets. Always verify and install the latest compatible React Native plugin version before changing dependencies.

## Workflow

1. Inspect the target React Native app first:
   - `package.json`, lockfile (`yarn.lock`, `package-lock.json`, or `pnpm-lock.yaml`), React Native version, `react-native.config.js`, New Architecture setting.
   - `android/build.gradle`, `android/app/build.gradle`, `android/app/src/main/AndroidManifest.xml`, proguard files, Java/Kotlin version, Gradle/AGP versions.
   - `ios/Podfile`, `ios/Podfile.lock`, `ios/*/Info.plist`, `ios/AppDelegate.swift` or `AppDelegate.mm`, `SceneDelegate`, deployment target, package dependencies.
   - Existing usage: `rg -n "react-native-telematics|TelematicsSdk|initializeSdk|setDeviceId|setEnableSdk|startManualTracking|startTrackAsPersistent|setTrackingMode|FutureTrack|PermissionWizard" .`.

2. Verify the latest plugin version before editing dependencies:
   - Published package: query npm with `npm view react-native-telematics version` and install that latest compatible version with the app's package manager.
   - Git dependency: query tags with `git ls-remote --tags --refs https://github.com/Mobile-Telematics/telematicsSDK-demoapp-react.git` and use the latest semantic version tag exactly when the user needs the repository version.
   - Do not hardcode the verified reference source version from this skill unless it is still the latest compatible published or tagged version.

3. Choose dependency style based on the app:
   - Published package: add `react-native-telematics` with the app's package manager.
   - Public Git dependency: use `https://github.com/Mobile-Telematics/telematicsSDK-demoapp-react.git` only when the user needs the repository version.
   - Do not edit native plugin internals in the app unless the task is to patch the plugin itself.

4. Load platform references only as needed:
   - `references/react-native/plugin-api.md` for TypeScript API, listeners, flow sequencing, and facade recommendations.
   - `references/android/host-setup.md` for Android manifest, Gradle, permissions, release shrink/proguard, and validation.
   - `references/ios/host-setup.md` for iOS Podfile/SPM, `Info.plist`, `AppDelegate`, `SceneDelegate`, and lifecycle forwarding.

5. Before implementing a new reusable React Native service/facade, ask which primary tracking flow should be placed first:
   - automatic tracking
   - standard manual tracking without tags
   - standard manual tracking with future tags
   - app-controlled persistent manual tracking without tags
   - app-controlled persistent manual tracking with future tags
   - one-time persistent manual tracking without tags
   - one-time persistent manual tracking with future tags
   If the user already stated the primary flow or product code makes it clear, use it without asking.

6. Prefer an app-owned TypeScript facade around the default `TelematicsSdk` export instead of calling the plugin directly from many components. The facade should own initialization, device ID assignment, SDK enablement, permission checks, manual tracking state, persistent mode policy, future-tag sequencing, listener subscription lifecycle, and platform guards.

7. Configure host platforms completely. React Native JS code alone is insufficient:
   - Android must have required permissions, Gradle/repository settings, release shrink settings, proguard rules when minified, and runtime permission handling before enabling SDK.
   - iOS must have `use_frameworks! :linkage => :dynamic`, required permission keys, background modes, BG task identifiers, app target SPM linkage for `TelematicsSDK`, and `RPEntry.initializeSDK()` plus lifecycle forwarding.

8. Implement flow methods in TypeScript with the selected primary flow first and mark it:
   - `// Primary Flow: <name requested by user>`
   - Use separate sections for other supported flows.

9. Validate with the narrowest available checks:
   - package install (`yarn install`, `npm install`, or app-standard command)
   - TypeScript/lint checks (`yarn tsc`, `yarn lint`, or app-standard scripts)
   - tests if present
   - Android build or smallest Gradle task after Android changes
   - `cd ios && pod install`, then iOS build where feasible after iOS changes

## Coding Rules

- Call `TelematicsSdk.initializeSdk()` exactly once during app startup before other plugin APIs. Do not call it again from each tracking start method. On iOS it resolves without initializing native SDK itself, so host `AppDelegate` still must call `RPEntry.initializeSDK()`.
- Keep one app-owned ownership point for plugin calls. Avoid direct calls from many screens unless the app architecture already has a deliberate feature boundary.
- Add listeners in lifecycle-owned code and always call `.remove()` during cleanup.
- Keep device identity separate from tracking flows and SDK tracking modes. Generated facades should expose an explicit `setDeviceId(...)` method for login/session binding and an explicit `logout()` method for user logout/account removal. Do not make start/stop tracking methods accept or reset the device ID.
- Treat the device ID as a Damoov-issued user identifier in GUID format, also known as DeviceToken — the same value visible as UserId in Damoov Datahub. One DeviceToken per app user. Two ways to obtain it — both via `POST https://user.telematicssdk.com/v1/Registration/create` with `InstanceId` + `InstanceKey` headers: (1) Damoov-generated: omit `CustomToken` → Damoov generates and returns a UUID; (2) App-provided: pass your own UUID as `CustomToken` body param → Damoov registers that UUID as the DeviceToken. Store the DeviceToken in the app's backend database linked to the user record. Do not use a locally generated UUID without registering it on the Damoov platform first. See https://docs.damoov.com/docs/set-up-the-sdk-login-and-api-authentication and https://docs.damoov.com/reference/create-sdk-user
- Do not add API-key or credentials setup to app code; the React Native plugin APIs used by this skill do not take credentials.
- Set device ID before enabling SDK or starting manual tracking, but do it through the separate identity method rather than inside each tracking flow method.
- Check `isAllRequiredPermissionsAndSensorsGranted()` before enable/start flows; use `showPermissionWizard(...)` when the product wants native permission onboarding. When calling `showPermissionWizard(enableAggressivePermissionsWizard, enableAggressivePermissionsWizardPage)`: `enableAggressivePermissionsWizard: true` means the user cannot close the wizard without completing all steps; `enableAggressivePermissionsWizardPage: true` means the user cannot advance past each page without granting the current permission. On Android the wizard covers Location (Always), Physical Activity, Battery Optimization, and GPS. On iOS the wizard covers Location (Always), Notifications, Motion & Fitness, and optionally Bluetooth.
- For automatic tracking, assume `initializeSdk()` and device ID setup already happened and call `setEnableSdk(true)`.
- For standard manual tracking, ensure the device ID has already been configured, verify permissions, enable SDK collection, call `setTrackingMode(TrackingMode.Standard)`, then `startManualTracking()`.
  > React Native uses `TrackingMode.Standard` / `TrackingMode.Persistent` (uppercase). Flutter uses `TrackingMode.standard` (lowercase). Do not copy casing from other platforms.
- For app-controlled persistent manual tracking, set `TrackingMode.Persistent`, start manual tracking, and restore `TrackingMode.Standard` when business logic ends persistent mode.
- For one-time persistent manual tracking, use `startTrackAsPersistent()` and do not add a redundant manual `setTrackingMode(TrackingMode.Standard)` reset unless the installed native API proves it does not restore automatically on that platform.
- Call `setMaxPersistentTrackingInterval(minutes)` before starting any persistent tracking session. Valid range: `5..600` minutes; default is 240 minutes (4 hours). Pass only values in the valid range — the native SDK enforces bounds. Persistent tracking stops at whichever comes first — an explicit `stopManualTracking()` call or the interval expiry — then the SDK waits for the next start.
- For manual-only product flows, stop manual tracking and then disable the SDK with `setEnableSdk(false)`. Keep the SDK enabled after manual stop only when the product intentionally combines manual trips with automatic tracking.
- Expose a relevant stop method for every supported flow: automatic disables SDK collection, standard manual stops tracking and disables SDK collection, tagged manual flows remove future tags before stopping, app-controlled persistent flows also restore `TrackingMode.Standard`, and one-time persistent flows do not manually restore `TrackingMode.Standard`.
- Starting tracking while tracking is already active is idempotent: the SDK continues recording the existing track and does not start a new one.
- Add future tags before starting a manually tagged trip; await the promise result before starting tracking where product correctness depends on tags being attached to the upcoming trip.
- For every future tag, `tag` is a required `string` and `source` is an optional `string`. Omit `source` when it is unavailable; do not require an empty or `undefined` placeholder.
- Remove future tags before disabling the SDK when cleanup depends on SDK/API availability.
- Treat tagged manual flows as future-tag flows for upcoming trips. Do not imply processed-trip tag editing unless the latest installed plugin exposes that API.
- Generated facades should expose all seven app-level flows explicitly: automatic, standard manual with and without future tags, app-controlled persistent manual with and without future tags, and one-time persistent manual with and without future tags.
- On iOS, call iOS-only methods/listeners only behind `Platform.OS === 'ios'`.
- On Android, call Android-only methods only behind `Platform.OS === 'android'`.
- Do not treat `logout()` as a temporary disable switch. It disables SDK and clears the device ID; use `setEnableSdk(false)` when logout semantics are not intended.
- `isRTLDEnabled()` checks whether the Real-Time Location Data service is active. RTD/RTLD is a Damoov platform service that streams live GPS position and speed while a trip is active. The RTD service must be enabled at the application or instance level in Damoov Datahub before RTLD callbacks deliver data (iOS: `addOnRtldColectedData` listener). Without Datahub configuration, `isRTLDEnabled()` returns false regardless of SDK state. See https://docs.damoov.com/docs/real-time-location-tracker — Full three-level enable flow (Datahub → backend user flag → SDK listener): `../references/rtld-flow.md`.
- Surface promise rejections to the caller/UI; do not swallow native bridge errors, platform errors, invalid arguments, or permission failures.
- Do not enable Android minification/resource shrinking unless the app has verified keep rules for Telematics SDK and React Native codegen artifacts.
- Keep host app platform changes minimal and explicit; avoid rewriting generated React Native files unless integration requires it.

## DeviceToken Registration Flow

For the full end-to-end flow (backend registers DeviceToken → passes it to mobile → SDK initialization),
see `../references/devicetoken-flow.md`.

- **Production registration** (server-side): `../../backend/damoov-backend-registration-skill/SKILL.md`
- **Test DeviceToken** (quick setup): `../../testing/damoov-integration-testing-skill/SKILL.md`

## After Tracking Is Set Up

To fetch trips, safety scores, and driving statistics via REST API using the DeviceToken:
see `../../backend/damoov-trips-statistics-skill/SKILL.md`.

## Official Docs

Use these docs for baseline behavior, but check current React Native plugin and native source before copying code:

- https://github.com/Mobile-Telematics/telematicsSDK-demoapp-react
- https://docs.damoov.com/docs/-download-the-sdk-and-install-it-in-your-environment
- https://docs.damoov.com/docs/tracking
- https://docs.damoov.com/docs/ios-sdk-incoming-tags
- https://docs.damoov.com/docs/trip-tag-for-ios-app
