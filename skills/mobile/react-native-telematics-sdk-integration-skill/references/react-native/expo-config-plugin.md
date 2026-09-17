# React Native Expo Config Plugin Reference

This reference covers the Expo config plugin shipped by `react-native-telematics`, verified at
version `3.1.2`. It applies only to Expo projects that use Continuous Native Generation (CNG): the
`ios/` and `android/` folders are produced by `expo prebuild` or EAS Build and are not edited by
hand. For projects whose native folders are committed and hand-edited, use
`../android/host-setup.md` and `../ios/host-setup.md` instead.

Verify the installed package's own `plugin/` directory and README before relying on any detail
here; the plugin evolves with the native SDK requirements.

## When To Use It

| Signal in the app | Path |
|---|---|
| `expo` key in `app.json`/`app.config.js`, `ios`/`android` absent or git-ignored, built with `expo prebuild` / EAS Build | Expo CNG — use this plugin |
| `ios/` and `android/` committed and edited directly, no prebuild step | Bare React Native — hand-edit, do not add the plugin |
| Both present and the team edits native files directly | Ask the user which path they maintain before changing anything |

Do not hand-edit generated native files on the Expo path. `expo prebuild` regenerates them, and
`expo prebuild --clean` deletes them first, so manual edits disappear without warning.

## Installation

```json
{
  "expo": {
    "plugins": ["react-native-telematics"]
  }
}
```

With options:

```json
{
  "expo": {
    "plugins": [
      [
        "react-native-telematics",
        {
          "motionUsageDescription": "This app uses motion data to automatically detect trips.",
          "locationWhenInUseUsageDescription": "This app uses your location to detect and record trips.",
          "locationAlwaysAndWhenInUseUsageDescription": "This app uses your location in the background to detect and record trips, even when the app is closed.",
          "skipInfoPlistPermissions": false
        }
      ]
    ]
  }
}
```

Then regenerate the native projects:

```bash
npx expo prebuild --clean
npx expo run:android
npx expo run:ios
```

| Option | Type | Default | Purpose |
|---|---|---|---|
| `motionUsageDescription` | `string` | plugin default string | `NSMotionUsageDescription` |
| `locationWhenInUseUsageDescription` | `string` | plugin default string | `NSLocationWhenInUseUsageDescription` |
| `locationAlwaysAndWhenInUseUsageDescription` | `string` | plugin default string | `NSLocationAlwaysAndWhenInUseUsageDescription` |
| `skipInfoPlistPermissions` | `boolean` | `false` | Skips only the three usage-description keys, for apps that manage permission strings elsewhere. Background modes and BG task identifiers are still added. |

All options are optional. Replace the default usage descriptions with product-specific text
before shipping to the App Store.

The plugin requires `@expo/config-plugins`, which Expo projects already have transitively
through `expo`. It is an optional peer dependency of `react-native-telematics`. If it cannot be
resolved, the plugin throws a named error at config-resolution time rather than failing later.

## What The Plugin Applies

### iOS

- `AppDelegate`: adds `import TelematicsSDK`, calls `RPEntry.initializeSDK()` and the
  `RPEntry.instance` forward inside `application(_:didFinishLaunchingWithOptions:)`, and adds
  the `handleEventsForBackgroundURLSession`, `applicationDidReceiveMemoryWarning`,
  `applicationWillTerminate`, and `performFetchWithCompletionHandler` forwards.
- Lifecycle forwards: adds exactly one of the two sets — the three scene methods on
  `SceneDelegate` for scene-based projects, or the three application-level methods on
  `AppDelegate` otherwise. It detects scene usage from a `SceneDelegate.swift` file or a
  `UIApplicationSceneManifest` entry in `Info.plist`. It never adds both.
- `Info.plist`: merges `UIBackgroundModes` (`fetch`, `location`, `remote-notification`) and
  `BGTaskSchedulerPermittedIdentifiers` (`sdk.damoov.apprefreshtaskid`,
  `sdk.damoov.appprocessingtaskid`) into existing arrays, and adds the three usage-description
  keys unless already set or `skipInfoPlistPermissions` is true. Existing values are never
  overwritten.
- Podfile: ensures dynamic framework linkage, which `TelematicsSDK` requires. On the modern Expo
  template this is set through `ios.useFrameworks` in `Podfile.properties.json` rather than by
  editing the Podfile.
- Swift Package Manager app-target fix: injects a `post_install` hook that attaches the
  `TelematicsSDK` Swift package product (exact version `7.2.0`) to the application target. See
  `../ios/host-setup.md` for why the pod target alone is not enough and which launch crash this
  prevents.

### Android

- `android/gradle.properties`: sets `android.experimental.disableCompileSdkChecks=true`, so the
  build accepts `com.telematicssdk:tracking:4.1.0` (which declares `minCompileSdk=37` in its AAR
  metadata) on stable `compileSdk 36`. It raises `android.compileSdkVersion` to `36` when it is
  lower and leaves a higher value alone, so an app already on `37` stays there. It adds
  `android.suppressUnsupportedCompileSdk=37.0` only when the resolved compile SDK is `37` or
  higher, since AGP 8.12 supports 36 natively and warns only about 37. See
  `../android/host-setup.md` for why requiring `compileSdk 37` breaks hosted CI builds.
- `android/build.gradle`: adds an `allprojects` block that appends
  `-Xskip-metadata-version-check` to every Kotlin compile task, guarded by the marker comment
  `// react-native-telematics: skip metadata version check`. On older templates that declare
  `compileSdkVersion` as a literal `ext` value, it raises that to `36` too.
- `android/app/build.gradle`: adds the Telematics Maven repository
  (`https://s3.us-east-2.amazonaws.com/android.telematics.sdk.production/`), core library
  desugaring with `com.android.tools:desugar_jdk_libs:2.1.5`, and the netty packaging excludes
  (`META-INF/INDEX.LIST`, `META-INF/io.netty.versions.properties`,
  `META-INF/versions/9/OSGI-INF/MANIFEST.MF`).

The plugin deliberately does **not** set `android.kotlinVersion` or raise the Kotlin Gradle
Plugin. See `../android/host-setup.md`; raising it breaks Expo's own modules.

## What Is Still The App's Job

The plugin wires the native module in. It does not make the SDK record trips. The app still has
to, in this order:

1. Call `TelematicsSdk.initializeSdk()` once at startup.
2. Register a DeviceToken through the Damoov backend and pass it to `setDeviceId(...)`.
3. Obtain runtime permissions, through `showPermissionWizard(...)` on Android or the iOS
   permission-wizard configuration APIs.
4. Enable collection with `setEnableSdk(true)` or start a manual tracking flow.

Confirm the native module is linked before debugging anything else:

```ts
const initialized = await TelematicsSdk.isInitializedSdk();
```

## iOS Scene Lifecycle Per Expo SDK

iOS 26 and newer terminate an app built against the iOS 26 SDK that has not adopted the UIScene
lifecycle. What `expo prebuild` generates depends on the Expo SDK version:

| Expo SDK | Scene support | Plugin behaviour |
|---|---|---|
| 55, 56 | None — no `UIApplicationSceneManifest`, no `SceneDelegate.swift` | Adds the three application-level forwards to `AppDelegate`. Build with the Xcode version that SDK supports. |
| 57 | Opt-in through `expo-build-properties`; once enabled, Expo uses its own `EXExpoAppSceneDelegate` and generates no `SceneDelegate.swift` | `expo prebuild` stops with an explanatory error. Add a `SceneDelegate.swift` yourself, then re-run prebuild. |
| 58 and newer | `expo prebuild` generates `SceneDelegate.swift` and the scene manifest | Picked up automatically, no extra work. |

On Expo SDK 57 with scenes opted in, `expo prebuild` reports:

```
[react-native-telematics] This project declares UIApplicationSceneManifest in Info.plist, but no SceneDelegate.swift was found to add the scene lifecycle forwards to.
```

Resolve it by adding a `SceneDelegate.swift` next to `AppDelegate.swift`:

```swift
internal import Expo

@objc(SceneDelegate)
class SceneDelegate: ExpoAppSceneDelegate {}
```

and pointing `UISceneDelegateClassName` at `$(PRODUCT_MODULE_NAME).SceneDelegate`. The plugin
adds the scene forwards to that file on the next prebuild.

Do not work around this error by forwarding the application-level methods instead. iOS does not
deliver them to a scene-based app, so tracking would degrade silently.

## Remote Builds (EAS And Other Hosted CI)

Nothing extra is needed. An Expo app using this plugin builds on a hosted worker with the same
Android SDK components a stock Expo app needs: the plugin's entire Gradle footprint is the
Telematics Maven repository, core library desugaring, the netty packaging excludes,
`-Xskip-metadata-version-check`, and the two `gradle.properties` lines above — no SDK platform,
build-tools, or NDK version beyond what the Expo template already pins.

This is worth checking explicitly when an Android build passes locally and fails on EAS.
`com.telematicssdk:tracking:4.1.0` declares `minCompileSdk=37`, and Android SDK Platform 37 ships
on the preview channel only: installable locally with
`sdkmanager --channel=3 "platforms;android-37"`, not installable on a hosted worker. Skipping the
AAR metadata check keeps the build on stable `compileSdk 36`, which is what the Expo template
already uses. Verified by building Expo SDK 55, 56, and 57 apps against an Android SDK
installation with Platform 37 removed.

The worker does need network access to the Telematics Maven repository at
`s3.us-east-2.amazonaws.com`.

## Idempotency And Limits

- Every edit is idempotent and non-destructive. Re-running `expo prebuild`, with or without
  `--clean`, does not duplicate imports, methods, or array entries, and existing values are
  merged into rather than replaced.
- The plugin recognizes the standard Swift `AppDelegate`/`SceneDelegate` templates and Groovy
  `build.gradle` files that current Expo and React Native templates generate. For an
  unrecognized shape — a Kotlin DSL `build.gradle.kts`, an Objective-C AppDelegate, a heavily
  customized delegate — it throws a descriptive error naming the file and what it expected
  instead of producing a broken project. Apply that file's changes by hand from
  `../ios/host-setup.md` or `../android/host-setup.md`.
- The plugin runs once per prebuild through `createRunOncePlugin`; listing it twice in `plugins`
  is not an error but has no additional effect.

## Validation

```bash
npx expo prebuild --clean
npx expo run:android
npx expo run:ios
```

After prebuild, confirm the edits landed before building:

- `ios/<App>/AppDelegate.swift` contains `RPEntry.initializeSDK()`.
- Exactly one of `AppDelegate.swift` or `SceneDelegate.swift` carries the active/foreground/background forwards.
- `ios/<App>/Info.plist` has the background modes and BG task identifiers.
- `ios/Podfile` contains the `post_install` hook marked `@react-native-telematics-sdk spm-app-target-fix`.
- `android/gradle.properties` has `android.experimental.disableCompileSdkChecks=true`, and `android.compileSdkVersion` at `36` or higher.
- `android/build.gradle` has the `// react-native-telematics: skip metadata version check` block.
- `android/app/build.gradle` has the Maven repository, desugaring, and packaging excludes.

If a build still fails after this, read the error against the app's integration path before
changing Gradle versions — most Kotlin metadata failures on Expo come from raising the Kotlin
Gradle Plugin, which is the bare React Native remedy, not the Expo one. A failure that names
`compile against version 37 or later of the Android APIs` is the separate AAR metadata check:
confirm `android.experimental.disableCompileSdkChecks=true` survived into the generated project
rather than raising `compileSdk` to 37.
