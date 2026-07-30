# Flutter Android Host Setup

This reference covers Android host app setup for the Damoov Flutter plugin. It is based on the plugin's Android implementation and README. Verify the installed plugin and Android Gradle Plugin versions before editing.

## Plugin Native Baseline

The verified plugin `1.2.0` requires Flutter `3.44.0` or later and uses:

- Android Gradle Plugin `9.3.0`
- Gradle `9.6.1`
- Compile SDK `37`
- Min SDK `24`
- Target SDK `36`
- Java target `17` and AGP built-in Kotlin with JVM target `17`
- Core-library desugaring `com.android.tools:desugar_jdk_libs:2.1.5`
- `com.telematicssdk:tracking:4.1.0`
- Damoov Maven repository `https://s3.us-east-2.amazonaws.com/android.telematics.sdk.production/`

The native Android SDK needs `compileSdk 37` or higher. Flutter `3.44` supports Android deployment API 24 through 37, so the Flutter host must keep `minSdk >= 24` even though the native SDK itself has a floor of 23.

## Compatibility Decision

Inspect the installed Flutter SDK, the plugin's `pubspec.yaml`, the host AGP, Gradle wrapper, Java toolchain, and existing Android plugins before changing dependencies.

- Flutter earlier than `3.44.0`: do not use plugin `1.2.0`. Select a plugin release that explicitly supports the app's Flutter version; do not modify the plugin in the package cache.
- Host `compileSdk` lower than `37`: upgrade through a supported host-toolchain path. Never lower the Damoov requirement to 36 as a workaround.
- API 37 requires AGP `9.1.1+` with Gradle `9.3.1+`; AGP `9.3.x` requires Gradle `9.5+`. The plugin's AGP `9.3.0` / Gradle `9.6.1` pair is a verified plugin baseline, not a command to overwrite every host app's wrapper or Android plugin.
- AGP 9 provides built-in Kotlin. Do not add `kotlin-android` or a second Kotlin plugin just to copy the plugin configuration. Preserve the host's generated Flutter configuration and configure JVM target 17 using the supported DSL for that toolchain.

If an existing host cannot make a supported API 37 upgrade, report the compatibility block and use an explicitly compatible plugin release. Do not claim that an older AGP is supported merely because a particular build happens to pass.

## Manifest

The plugin manifest contributes location, storage, and activity-recognition permissions plus an `android:name` application value. Host apps commonly need manifest merge controls.

Add `tools` namespace and `tools:replace` when required:

```xml
<manifest
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

    <application
        tools:replace="android:label,android:name">
        ...
    </application>
</manifest>
```

Use Android runtime permission requests in the app before enabling SDK or manual tracking. The plugin's Android bridge returns `MISSING_PERMISSION` if `ACCESS_FINE_LOCATION` is not granted when enabling SDK.

The plugin manifest also sets `android:requestLegacyExternalStorage="true"` on its application entry. Preserve or explicitly resolve this during manifest merge only after checking the target app's Android API and storage policy.

## Gradle

The Flutter plugin should bring its native dependency transitively. If the app needs direct native access or advanced `Application` customization, add the Damoov repository and dependency in the native Android module after checking existing Gradle structure.

Repository:

```groovy
maven {
    url "https://s3.us-east-2.amazonaws.com/android.telematics.sdk.production/"
}
```

Dependency for direct native access:

```groovy
implementation "com.telematicssdk:tracking:4.1.0"
```

When the host needs the Android settings explicitly, adapt this Groovy example to its existing Gradle shape rather than copying root plugin declarations:

```groovy
android {
    compileSdkVersion 37

    defaultConfig {
        minSdkVersion 24
        targetSdkVersion 36
    }

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"
}
```

On AGP 9, Kotlin is provided by AGP. Do not add `apply plugin: 'kotlin-android'` solely for this snippet.

Release settings recommended by the plugin README:

```groovy
android {
    buildTypes {
        release {
            shrinkResources false
            minifyEnabled false
        }
    }
}
```

If the product requires minification, do not just enable it. Add and verify keep rules first.

## Proguard

Add when the host app uses minification or already has proguard files:

```proguard
-keep public class com.telematicssdk.tracking.** {*;}
```

The plugin example also uses a host `proguard-files.pro`; follow the app's existing file naming.

## Advanced Tracking Settings

For native Android settings, choose one application strategy. `TelematicsSDKApp` is a convenience `Application` base class with preset Android SDK initialization; it is not mandatory for every Flutter integration.

Use `TelematicsSDKApp` when all of these are true:

- The Flutter host app can own its Android `Application` class.
- The app does not already need a different `Application`/`FlutterApplication` base class or another SDK-provided base class.
- The product accepts the preset initialization shape and only needs to customize settings by overriding `setTelematicsSettings()`.

Do not inherit from `TelematicsSDKApp` when the app already has an `Application` class that initializes Flutter, DI, analytics, crash reporting, notifications, or another SDK. In that case, keep the existing base class and call `TrackingApi.getInstance().initialize(this, settings)` manually from `onCreate()`.

Kotlin/Java cannot inherit from both `FlutterApplication` and `TelematicsSDKApp`.

Option 1: inherit from `TelematicsSDKApp` for convenience preset initialization:

```kotlin
import com.telematicssdk.TelematicsSDKApp
import com.telematicssdk.tracking.Settings

class App : TelematicsSDKApp() {
    override fun setTelematicsSettings(): Settings {
        return Settings()
            .stopTrackingTimeout(Settings.stopTrackingTimeHigh)
            .accuracy(Settings.accuracyHigh)
            .autoStartOn(true)
            .passiveDetectionOn(true)
    }
}
```

Option 2: keep the existing app `Application`/`FlutterApplication` class and initialize native tracking settings manually:

```kotlin
import io.flutter.app.FlutterApplication
import com.telematicssdk.tracking.TrackingApi
import com.telematicssdk.tracking.Settings

class App : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()

        val api = TrackingApi.getInstance()
        if (!api.isInitialized()) {
            api.initialize(this, telematicsSettings())
        }
    }

    private fun telematicsSettings(): Settings {
        return Settings()
            .stopTrackingTimeout(Settings.stopTrackingTimeHigh)
            .accuracy(Settings.accuracyHigh)
            .autoStartOn(true)
            .passiveDetectionOn(true)
    }
}
```

Then set the chosen class in `AndroidManifest.xml`:

```xml
<application android:name=".App">
    ...
</application>
```

Only add this when the app needs native tracking settings. For ordinary Flutter integration, prefer Dart `TrackingApi` methods.

Decision summary:

- No custom native settings needed: do not add an app `Application` class just for this; configure Flutter/Dart integration and host permissions.
- Custom native settings and no existing `Application` base conflict: use `TelematicsSDKApp` and override `setTelematicsSettings()`.
- Existing `Application` class or base-class conflict: do not use `TelematicsSDKApp`; initialize `TrackingApi` manually with the same `Settings()` builder values.

## Testing Notes

Android Emulator can validate integration flow, permissions, and trip recording — but only
if a location feed is active. **By default the emulator is stationary**, so without enabling
simulation the SDK receives no movement and records no trip (`ActivityStatus` stays
`"No Data"` and no trip appears in Datahub).

To feed location on the emulator:
- CLI (auto-start, preferred by the skill): generate a short route as a series of points
  ~2s apart at driving speed, then continue until the route is long enough for trip
  detection:
  ```bash
  adb emu geo fix -122.0332 37.3324
  sleep 2; adb emu geo fix -122.0450 37.3639
  sleep 2; adb emu geo fix -122.0800 37.3939
  sleep 2; adb emu geo fix -122.1100 37.4139
  ```
- UI: Android Emulator → Extended controls → **Location** → load a GPX/KML route →
  **Play Route**.
- If `adb` reports no devices, ask the developer to boot an emulator and replay a route.

HF Data (accelerometer/gyroscope) cannot be fully tested on the emulator; validate final
background and sensor-heavy behavior on a physical device.

## Android-Specific Dart Calls

Guard Android-specific methods:

```dart
if (Platform.isAndroid) {
  await trackingApi.setAndroidAutoStartEnabled(
    enable: true,
    permanent: true,
  );
}
```

Do not call Android-only methods on iOS.

## Validation

After Android changes, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Before the build, inspect the resolved `compileSdk`, `minSdk`, `targetSdk`, AGP, Gradle wrapper, Java version, and desugaring dependency. If a full build is too expensive locally, at minimum run `flutter pub get`, `flutter analyze`, and inspect manifest merge/build errors from the smallest Gradle task available in the app.
