# React Native Android Host Setup

This reference covers Android host app setup for `react-native-telematics`. It is based on the public plugin's Android implementation and README. Verify the installed plugin and Android Gradle Plugin versions before editing.

## Plugin Native Baseline

The verified plugin `3.1.0` requires React Native `0.86.0` or later. Its RN 0.86 example validates:

- Gradle wrapper `9.3.1`
- Android Gradle Plugin `8.12.0`
- Kotlin `2.3.21` through Kotlin BOM and stdlib
- Compile SDK `37`
- Min SDK `24`
- Target SDK `36`
- Java target `17`
- `com.telematicssdk:tracking:4.1.0`
- Damoov Maven repository `https://s3.us-east-2.amazonaws.com/android.telematics.sdk.production/`
- `coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"`

`compileSdk 37` is mandatory: the plugin resolves `TelematicsSdk_compileSdkVersion` from root `ext` values or root Gradle properties, falls back to 37, and fails the build if the result is lower. Keep `minSdk >= 24` for React Native hosts. The source example's AGP 8.12 / Gradle 9.3.1 pair is a validated plugin/example combination, not a universal host-upgrade recipe; it may show an unsupported-compile-SDK warning. Do not copy its wrapper, AGP, Kotlin version, or warning suppression blindly into another app.

React Native `0.82+` is New Architecture-only. For plugin `3.1.0`, build and validate the TurboModule on the host's generated RN 0.86+ configuration; setting `newArchEnabled=false` does not restore a legacy runtime.

## Manifest

The plugin manifest contributes:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

The README also requires network permissions in the host app:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

Remove `android:allowBackup="true"` from the host application manifest if present, per plugin README.

`TrackingPermissionsWizardActivity` is already declared by the plugin manifest and merged by React Native autolinking. Do not add a duplicate activity declaration to the host manifest.

Use Android runtime permission requests in the app before enabling SDK or manual tracking. The Android bridge rejects `setEnableSdk` with `INVALID_PERMISSION` when `ACCESS_FINE_LOCATION` is not granted.

## Gradle

The React Native package brings `com.telematicssdk:tracking:4.1.0` and `react-android` transitively. Do not add a second Damoov dependency or pin a `react-android` artifact version in the host app just to integrate the plugin.

The Damoov Maven repository must be visible in the host's active dependency-resolution scope. Add it to the app module only when that is how the project resolves repositories:

```groovy
maven {
    url "https://s3.us-east-2.amazonaws.com/android.telematics.sdk.production/"
}
```

For projects using `RepositoriesMode.PREFER_SETTINGS`, add the same repository under `dependencyResolutionManagement.repositories` in `android/settings.gradle` instead. Do not put it only in an ignored repository block.

Only if the product deliberately calls the native Android SDK outside the React Native plugin, add the native dependency after confirming it does not duplicate plugin initialization:

```groovy
implementation "com.telematicssdk:tracking:4.1.0"
```

Set SDK levels through the host's existing Gradle style. The plugin reads an optional `TelematicsSdk_compileSdkVersion` override from root `ext` or root Gradle properties, but it must resolve to 37 or higher:

```groovy
android {
    compileSdk 37

    defaultConfig {
        minSdk 24
        targetSdk 36
    }
}
```

Keep Java 17 and desugaring:

```groovy
android {
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"
}
```

The verified example resolves Kotlin `2.3.21` with the Kotlin BOM and standard library. Check the host's Kotlin dependency resolution before adding either; do not add a second Kotlin plugin or force a version that conflicts with the installed React Native build.

Release settings recommended by the example:

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

When minification is enabled or the app already has proguard files, include:

```proguard
-keep public class com.telematicssdk.tracking.** {*;}
-keep class com.reactnativetelematicssdk.** { *; }
```

Also preserve React Native codegen/TurboModule rules according to the app's React Native version.

## Android Initialization Behavior

`TelematicsSdk.initializeSdk()` calls native Android `TrackingApi.initialize(context, settings)` with high accuracy, high stop timeout, autostart enabled, and passive detection enabled. It also registers tag, location, and tracking callbacks.

Do not add a custom native `Application` initialization unless the product needs settings that differ from the plugin defaults. If custom native initialization is required, verify that it does not conflict with the module's own `initializeSdk()` behavior.

## Android-Specific JS Calls

Guard Android-specific methods:

```ts
if (Platform.OS === 'android') {
  await TelematicsSdk.setAndroidAutoStartEnabled({
    enable: true,
    permanent: true,
  });
}
```

Do not call Android-only methods on iOS; the native iOS bridge rejects them with `PLATFORM_ERROR`.

## Validation

After Android changes, run the app-standard checks:

```bash
yarn install
yarn lint
yarn typescript
cd android && ./gradlew assembleDebug
```

Before building, inspect the resolved `compileSdk`, `minSdk`, `targetSdk`, Gradle wrapper, AGP, Java/Kotlin versions, desugaring dependency, repository mode, and `newArchEnabled` setting. For npm apps, use equivalent scripts from `package.json`. If a full Android build is too expensive locally, at minimum run package install, TypeScript/lint checks, and a Gradle sync or smallest available Gradle task.
