# React Native Android Host Setup

This reference covers Android host app setup for `react-native-telematics`. It is based on the public plugin's Android implementation and README. Verify the installed plugin and Android Gradle Plugin versions before editing.

On an Expo CNG project the config plugin applies most of this automatically during `expo prebuild`; see `../react-native/expo-config-plugin.md` and treat this file as the explanation of what it does and as the manual path for bare React Native apps. Each step below states which path it belongs to where they differ.

## Plugin Native Baseline

The verified plugin `3.1.2` declares `react-native >=0.83.0` and is verified on React Native `0.83.10` (Expo SDK 55), `0.85.3` (Expo SDK 56), and `0.86.3` (Expo SDK 57). Its RN 0.86 example validates:

- Gradle wrapper `9.3.1`
- Android Gradle Plugin `8.12.0`
- Kotlin `2.3.21` through Kotlin BOM and stdlib
- Compile SDK `36`
- Min SDK `24`
- Target SDK `36`
- Java target `17`
- `com.telematicssdk:tracking:4.1.0`
- Damoov Maven repository `https://s3.us-east-2.amazonaws.com/android.telematics.sdk.production/`
- `coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.5"`

Keep `minSdk >= 24` for React Native hosts. The source example's AGP 8.12 / Gradle 9.3.1 pair is a validated plugin/example combination, not a universal host-upgrade recipe. Do not copy its wrapper, AGP, or Kotlin version blindly into another app.

React Native `0.82+` is New Architecture-only. For plugin `3.1.2`, build and validate the TurboModule on the host's generated RN 0.83+ configuration; setting `newArchEnabled=false` does not restore a legacy runtime.

## Compile SDK — `36` Plus One Gradle Property

Plugin `3.1.2` builds on stable `compileSdk 36`. Earlier versions required `37`; do not carry that rule forward.

Add to `android/gradle.properties` (the Expo config plugin sets this automatically):

```properties
android.experimental.disableCompileSdkChecks=true
```

Without it, AGP refuses the dependency:

```text
Dependency 'com.telematicssdk:tracking:4.1.0' requires libraries and applications that depend on
it to compile against version 37 or later of the Android APIs.
```

`com.telematicssdk:tracking:4.1.0` declares `minCompileSdk=37` in its AAR metadata, but that is only the compile SDK the AAR was built with. Nothing in it needs API 37: its highest transitive requirement is 36 (`androidx.activity 1.13.0`), its bytecode references no class added in API 37, and its resources stop at `values-v31`.

This matters for remote builds. **Android SDK Platform 37 is preview-channel only.** A developer can install it with `sdkmanager --channel=3 "platforms;android-37"`, but EAS and other hosted CI workers cannot install anything, so a build that insists on `compileSdk 37` succeeds locally and fails on CI. Building against stable `compileSdk 36` with the property above works in both places, and plugin `3.1.2` verifies it by building the example app in debug and release and by building Expo SDK 55, 56, and 57 apps against an Android SDK installation with Platform 37 removed.

State the cost when recommending it: the property relaxes the AAR metadata check for **every** dependency in the app, not only the Telematics SDK. If another library genuinely needs a higher compile SDK, that surfaces later as a compile or runtime error instead of at this check.

### Scope Of This Baseline

`compileSdk 36` is the right baseline for React Native and Expo hosts specifically, because their toolchain does not reliably support 37: AGP 8.12 ships with the React Native 0.86 Android toolchain and warns on 37, and Expo's hosted workers cannot install the preview-channel platform. The native Android and Flutter integration skills stay on `compileSdk 37`, which their toolchains support without either problem. If those skills disagree with this one about the compile SDK, that is intentional — do not carry a value across stacks.

### Staying On Compile SDK 37

Supported, and sometimes the right call when an app already depends on another library that needs 37. Then:

- set the app's `compileSdk` to 37, or `TelematicsSdk_compileSdkVersion=37` for this module alone;
- add `android.suppressUnsupportedCompileSdk=37.0`, since AGP 8.12 warns for 37;
- make sure Platform 37 is installed on every build machine, including CI workers.

### How The Module Resolves Its Compile SDK

`3.1.2` inherits the host app's `compileSdkVersion` and falls back to `36`; `TelematicsSdk_compileSdkVersion` overrides it for this module alone. Earlier versions read only the module-specific property, which silently left the module behind on the fallback in an app on a higher compile SDK.

Two build failures, with different fixes:

| Failure | Meaning | Fix |
|---|---|---|
| `react-native-telematics requires compileSdk 36 or higher.` | Resolved compile SDK is below 36. | Raise the app `compileSdk`, or set `TelematicsSdk_compileSdkVersion` to 36 or higher. |
| `react-native-telematics builds on compileSdk 36, but com.telematicssdk:tracking:4.1.0 declares minCompileSdk=37 in its AAR metadata.` | Compile SDK is below 37 and the property is not set. | Add `android.experimental.disableCompileSdkChecks=true`, or move to `compileSdk 37`. |

## Remote And Hosted CI Builds

An app using this plugin needs no preview-channel SDK component: with `compileSdk 36` and the property above, a hosted worker builds with the same Android SDK components a stock React Native or Expo app needs — no extra SDK platform, build-tools, or NDK version.

The worker does need network access to the Telematics Maven repository at `s3.us-east-2.amazonaws.com`.

If Android builds pass locally and fail only on CI, check the resolved `compileSdk` and whether `android.experimental.disableCompileSdkChecks` reached the generated project before looking anywhere else.

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

Set SDK levels through the host's existing Gradle style. The plugin inherits the host `compileSdkVersion` and accepts an optional `TelematicsSdk_compileSdkVersion` override from root `ext` or root Gradle properties; the resolved value must be 36 or higher:

```groovy
android {
    compileSdk 36

    defaultConfig {
        minSdk 24
        targetSdk 36
    }
}
```

Pair it with `android.experimental.disableCompileSdkChecks=true` in `android/gradle.properties` — see "Compile SDK" above.

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

### Kotlin Toolchain — Path-Dependent

`com.telematicssdk:tracking:4.1.0` brings in `kotlin-stdlib` 2.3.x and ships Kotlin metadata `2.3.0`. React Native pins the Kotlin Gradle Plugin well below that (`2.1.20` on 0.83/0.85/0.86). The remedy differs by integration path, and the two are **not interchangeable**.

**Bare React Native** — set the Kotlin Gradle Plugin to `2.3.21` on the root buildscript classpath and add the Kotlin BOM to the app module:

```groovy
// android/build.gradle
buildscript {
    dependencies {
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.21"
    }
}
```

```groovy
// android/app/build.gradle
dependencies {
    implementation platform("org.jetbrains.kotlin:kotlin-bom:2.3.21")
}
```

The BOM is required, not optional. Without it, stdlib and reflect can resolve to a version older than the compiler and fail with `Class 'X' was compiled with an incompatible version of Kotlin`.

**Expo** — do not raise the Kotlin Gradle Plugin and do not set `android.kotlinVersion`. Expo pins its own Kotlin compiler to build Expo's own modules, independent of what the host project declares. Verified failures when it is raised:

- Expo SDK 55 fails at configuration time: `Failed to apply plugin 'expo-root-project'. Can't find KSP version for Kotlin version '2.3.21'.`
- Expo SDK 56 fails compiling Expo's own module: `Execution failed for task ':expo-modules-core:compileDebugKotlin'`, `Unresolved reference 'map'`, and `Module was compiled with an incompatible version of Kotlin. The binary version of its metadata is 2.3.0, expected version is 2.1.0.`

Instead, let Expo's pinned compiler read the newer metadata:

```groovy
// android/build.gradle
allprojects {
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile).configureEach {
        compilerOptions {
            freeCompilerArgs.add("-Xskip-metadata-version-check")
        }
    }
}
```

The Expo config plugin adds this automatically during `expo prebuild`; Expo apps using it have nothing to do by hand.

### Kotlin Gradle Plugin Warning

Plugin `3.1.2` checks the root buildscript classpath after project evaluation and logs a warning — never a build failure — when it resolves a Kotlin Gradle Plugin below `2.3.0`:

```text
[react-native-telematics] com.telematicssdk:tracking:4.1.0 ships Kotlin metadata 2.3.0.
Kotlin Gradle Plugin <version> on the root buildscript classpath cannot read it as-is.
```

On an Expo app using `-Xskip-metadata-version-check` this warning is expected and harmless. On a bare React Native app it means the Kotlin Gradle Plugin still needs to be raised to `2.3.21`. Read it against the app's integration path before changing anything.

### Packaging Excludes

The SDK depends on netty, whose `META-INF` entries collide during packaging in the host app. The library module's own packaging block does not apply to the app, so add them in `android/app/build.gradle` (the Expo config plugin adds these for you):

```groovy
android {
    packaging {
        resources {
            excludes += [
                'META-INF/INDEX.LIST',
                'META-INF/io.netty.versions.properties',
                'META-INF/versions/9/OSGI-INF/MANIFEST.MF'
            ]
        }
    }
}
```

### Compile SDK Warning Suppression

Only needed on `compileSdk 37` or higher, where AGP 8.12 warns:

```properties
android.suppressUnsupportedCompileSdk=37.0
```

On the recommended `compileSdk 36` baseline this property is unnecessary — AGP 8.12 supports 36 natively. The Expo config plugin adds it only when the resolved compile SDK is 37 or higher.

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

On an Expo CNG project, run `npx expo prebuild --clean` first and validate the generated output, then build with `npx expo run:android`. Do not edit the generated Gradle files directly.

Before building, inspect the resolved `compileSdk`, `android.experimental.disableCompileSdkChecks`, `minSdk`, `targetSdk`, Gradle wrapper, AGP, Java/Kotlin versions, the Kotlin Gradle Plugin version on the root buildscript classpath, desugaring dependency, packaging excludes, repository mode, and `newArchEnabled` setting. For npm apps, use equivalent scripts from `package.json`. If a full Android build is too expensive locally, at minimum run package install, TypeScript/lint checks, and a Gradle sync or smallest available Gradle task.
