# Common SDK Surface

This reference covers public Android TelematicsSDK APIs that are common to every integration, regardless of the app's primary tracking flow or SDK tracking mode.

Use published Damoov docs as baseline setup guidance, but verify method names and deprecations against the installed SDK dependency artifacts before editing app code.

## Android Project Setup

Every integration should inspect the target app for:

- Repository: Maven repository `https://s3.us-east-2.amazonaws.com/android.telematics.sdk.production/` unless the app uses an internal mirror.
- Dependency: `implementation("com.telematicssdk:tracking:<version>")`.
- SDK levels: Android SDK `4.1.0` requires `compileSdk 37` or higher, has native minimum SDK `23`, and uses target SDK `36` as its verified baseline. Do not lower `compileSdk` to accommodate an older host toolchain.
- Toolchain: Java/Kotlin target `17`; enable core-library desugaring with `com.android.tools:desugar_jdk_libs:2.1.5`.
- API 37 compatibility: use AGP `9.1.1+` with Gradle `9.3.1+` at minimum. AGP `9.3.x` requires Gradle `9.5+`; the verified SDK baseline is AGP `9.3.0` and Gradle `9.6.1`. Check Android Studio, project plugins, and CI before upgrading the host rather than copying versions blindly.
Use this Kotlin DSL shape when the host app needs to set the SDK 4.1 build requirements explicitly:

```kotlin
android {
    compileSdk = 37

    defaultConfig {
        minSdk = 23
        targetSdk = 36
    }

    compileOptions {
        coreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
```

Adapt the syntax to Groovy or a version catalog when that is what the host already uses. Do not add a second Kotlin/AGP plugin declaration solely to copy this snippet.

- Packaging excludes for Kotlin DSL:

```kotlin
android {
    packaging {
        resources {
            excludes += setOf(
                "META-INF/INDEX.LIST",
                "META-INF/io.netty.versions.properties"
            )
        }
    }
}
```

- Proguard/R8 keep rule when minification is enabled:

```proguard
-keep public class com.telematicssdk.tracking.** {*;}
```

The verified SDK checkpoint is `4.1.0`. Do not downgrade or select a version from changelog entries alone. Re-check the app's resolved dependency, the user-requested version, or available Maven metadata before each dependency edit.

## Manifest And Permissions

The SDK library manifest declares these permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="com.google.android.gms.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

It also declares foreground location services, boot/keep-alive receivers, a permissions wizard activity, GPS permission activity, and a file provider with authority `${applicationId}.trackingprovider`.

Important checks:

- Verify the merged manifest after integration.
- Do not remove SDK permissions via manifest merge rules unless the product accepts the runtime behavior.
- Do not add `maxSdkVersion` to SDK-required permissions without verifying SDK behavior.
- Ensure the final app has a valid notification strategy for foreground location service requirements on modern Android.

Runtime permissions must be granted before enabling the SDK:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION` on Android 10+
- `ACTIVITY_RECOGNITION` on Android 10+
- battery optimization exemption flow where required by product policy
- `POST_NOTIFICATIONS` on Android 13+ if foreground service notifications are user-visible

Use `TrackingApi.getInstance().isAllRequiredPermissionsAndSensorsGranted()` as the SDK gate before `setEnableSdk(true)`.

## Initialization And Settings

Initialize from `Application.onCreate()`:

```kotlin
class App : Application() {
    override fun onCreate() {
        super.onCreate()

        val settings = Settings()
            .accuracy(Settings.accuracyHigh)
            .stopTrackingTimeout(Settings.stopTrackingTimeHigh)
            .autoStartOn(true)
            .adOn(false)
            .passiveDetectionOn(false)

        TrackingApi.getInstance().initialize(this, settings)
    }
}
```

`Settings()` defaults in SDK 4.x:

- `accuracy = Settings.accuracyHigh` (`100` meters)
- `stopTrackingTimeout = Settings.stopTrackingTimeHigh` (`5` minutes)
- `autoStartOn = true`
- `adOn = false`
- `passiveDetectionOn = false`

Builder functions:

- `accuracy(value: Int)` with presets `Settings.accuracyLow`, `Settings.accuracyNormal`, `Settings.accuracyHigh`.
- `stopTrackingTimeout(value: Int)` with presets `Settings.stopTrackingTimeLow`, `Settings.stopTrackingTimeNormal`, `Settings.stopTrackingTimeHigh`.
- `autoStartOn(value: Boolean)`.
- `adOn(value: Boolean)`.
- `passiveDetectionOn(value: Boolean)`.

Avoid old `Settings(...)` constructors with HF/ELM arguments.

## Core TrackingApi Methods

Common SDK 4.x APIs documented for `TrackingApi`:

- `TrackingApi.getInstance()`
- `initialize(context: Context, settings: Settings?)`
- `initialize(context: Context)`
- `isInitialized(): Boolean`
- `setDeviceID(deviceId: String)`
- `isDeviceIdEmpty(): Boolean`
- `isDeviceIdValid(): Boolean`
- `getDeviceId(): String`
- `clearDeviceID()`
- `logout()`
- `getDeviceIdRegistrationState(): DeviceIdRegistrationState`
- `setEnableSdk(enable: Boolean)`
- `isSdkEnabled(): Boolean`
- `isSdkDisablePending(): Boolean`
- `setAutoStartEnabled(enabled: Boolean, permanent: Boolean)`
- `isAutoStartEnabled(): Boolean`
- `isAllRequiredPermissionsAndSensorsGranted(): Boolean`
- `isAllRequiredPermissionsGranted(): Boolean`
- `areAllRequiredPermissionsAndSensorsGranted(): Boolean`
- `areAllRequiredPermissionsGranted(): Boolean`
- `isTracking(): Boolean`
- `startTracking(): Boolean`
- `startTrackAsPersistent(): Boolean`
- `stopTracking(): Boolean`
- `setTrackingMode(mode: TrackingMode)`
- `getTrackingMode(): TrackingMode`
- `setMaxPersistentTrackingInterval(minutes: Int)`
- `getMaxPersistentTrackingInterval(): Int`
- `getTrackingState(): TrackingState`
- `getTrackStartDate(): Long?`

Keep SDK enablement and SDK logout as separate repository operations. `setEnableSdk(false)` disables collection without expressing account/device identity removal. `logout()` is a separate identity/logout operation and should not be hidden inside `disableSdk()`.
- `getSdkVersion(): String`

`startPersistentTracking()` exists but is deprecated in SDK 4.x. Use `startTrackAsPersistent()`.

## Status Models

```kotlin
data class TrackingState(
    val automaticTrackingStatus: TrackingStatus,
    val manualTrackingStatus: TrackingStatus
)

enum class TrackingStatus {
    ENABLED,
    DEVICE_ID_NOT_SET,
    SDK_DISABLED,
    DISABLED_BY_SETTINGS,
    DISABLED_BY_SERVER,
    DISABLED_BY_SCHEDULE
}

data class DeviceIdRegistrationState(
    val status: DeviceIdRegistrationStatus,
    val checkedAtMillis: Long?
)

enum class DeviceIdRegistrationStatus {
    UNKNOWN,
    NOT_SET,
    VALID,
    INVALID
}
```

Use these SDK state APIs instead of inferring state with custom app-side booleans.

## Permissions Wizard

SDK 4.1 exposes `com.telematicssdk.tracking.utils.permissions.TrackingPermissionsWizardActivity`. Do not use pre-4.1 wizard classes or parameters.

Use `TrackingPermissionsWizardThemeMode.Light`, `.Dark`, or `.System` and the two boolean options:

- `blockEarlyExit`: prevent the user from leaving the wizard before it completes.
- `skipWizardPages`: omit the informational pages.

Both default to `false`; `System` is the default theme. Keep SDK `Intent` creation in the repository or permission coordinator, and launch it from Activity/Compose through Activity Result APIs:

```kotlin
import android.content.Context
import android.content.Intent
import com.telematicssdk.tracking.utils.permissions.TrackingPermissionsWizardActivity
import com.telematicssdk.tracking.utils.permissions.TrackingPermissionsWizardThemeMode

interface TelematicsRepository {
    /** Creates the SDK 4.1 wizard intent for Activity Result API launch. */
    fun createPermissionsWizardIntent(
        context: Context,
        themeMode: TrackingPermissionsWizardThemeMode = TrackingPermissionsWizardThemeMode.System,
        blockEarlyExit: Boolean = false,
        skipWizardPages: Boolean = false,
    ): Intent
}

class DefaultTelematicsRepository : TelematicsRepository {
    override fun createPermissionsWizardIntent(
        context: Context,
        themeMode: TrackingPermissionsWizardThemeMode,
        blockEarlyExit: Boolean,
        skipWizardPages: Boolean,
    ): Intent = TrackingPermissionsWizardActivity.getStartWizardIntent(
        context,
        themeMode = themeMode,
        blockEarlyExit = blockEarlyExit,
        skipWizardPages = skipWizardPages,
    )
}
```

```kotlin
private val permissionsWizardLauncher =
    registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        when (result.resultCode) {
            TrackingPermissionsWizardActivity.WIZARD_RESULT_ALL_GRANTED -> {
                // Enable SDK or call the confirmed product workflow.
            }
            TrackingPermissionsWizardActivity.WIZARD_RESULT_NOT_ALL_GRANTED,
            TrackingPermissionsWizardActivity.WIZARD_RESULT_CANCELED -> {
                // Forward the state to UI using the host app's error/result model.
            }
        }
    }
```

For Compose, create the launcher with `rememberLauncherForActivityResult(...)`, obtain `Context` from `LocalContext.current`, and launch the repository-created intent from an event handler. Do not hardcode wizard result text in Kotlin; get user-visible strings from the host app's `Settings`/localization layer.

## Trip Metadata

Use Properties for trip metadata and Sub-units for analytical classification. These methods accept flat `Map<String, String>` values; never store personally identifiable information.

```kotlin
val api = TrackingApi.getInstance()

api.setProperties(mapOf("order" to "A-42"))
val properties = api.getProperties()
api.clearProperties()

api.setSubUnits(mapOf("vehicle" to "van-7"))
val subUnits = api.getSubUnits()
api.clearSubUnits()

api.addActivityLog("Arrived at depot", emptyMap())
```

- `setProperties` and `setSubUnits` replace the complete old map; read first when changing one key. Do not pass an empty map to clear it.
- Properties allow 1–20 entries. A change during active tracking completes the current trip and starts the next trip with the replacement.
- Sub-units allow 1–5 entries. Changes never restart active tracking and apply to the next trip.
- Keys and values must be non-empty and no longer than 255 characters. Both maps clear on logout or DeviceToken change.
- Call `addActivityLog` only while tracking is active. It neither stops nor splits tracking; text must be 1–1000 characters and a trip accepts at most 100 entries. Pass `emptyMap()` when no event data is needed.
- Future Tags are deprecated for new metadata integrations. Keep them only for backwards-compatible flows.

## Listeners And Receivers

`TrackingStateListener`:

```kotlin
interface TrackingStateListener {
    fun onStartTracking()
    fun onStopTracking()
}
```

Register with `registerCallback(listener)` and unregister with `unregisterCallback(listener)`.

`LocationListener`:

```kotlin
interface LocationListener {
    fun onLocationChanged(location: Location?)
}
```

Register with `setLocationListener(listener)` and clear with `setLocationListener(null)`.

`TrackingEventsReceiver` can be registered by class with `registerTrackingEventsReceiver(receiver)` and unregistered with `unregisterTrackingEventsReceiver()`. Subclasses receive location, start/stop, speed violation, new events, and SDK deprecated events.

`TagsProcessingListener` and `TagsProcessingReceiver` handle future tag operation results. Register callback with `addTagsProcessingCallback(callback)` or receiver class with `registerTagsReceiver(receiver)`. Remove callback with `removeTagsProcessingCallback()` and unregister receiver with `unregisterTagsReceiver()`.

Generated examples should log or forward events to the appropriate repository/domain handler only. Do not put business decisions directly inside SDK callbacks unless explicitly requested.

## Repository Coverage Checklist

For complete SDK integration, do not stop after manual tracking flows. Add repository methods for every SDK API group that the app can reasonably expose.

`TelematicsRepository` owns management and tracking:

- initialization/settings: `initialize(context, settings?)`, `isInitialized()`
- device identity: `setDeviceID`, `isDeviceIdEmpty`, `isDeviceIdValid`, `getDeviceId`, `clearDeviceID`, `getDeviceIdRegistrationState`, `logout`
- SDK enablement: `setEnableSdk`, `isSdkEnabled`, `isSdkDisablePending`
- auto-start: `setAutoStartEnabled`, `isAutoStartEnabled`
- permissions/sensors: all required permission/sensor checks
- tracking: `isTracking`, `startTracking`, `startTrackAsPersistent`, `stopTracking`, `getTrackStartDate`, `getTrackingState`
- tracking modes: `setTrackingMode`, `getTrackingMode`, `setMaxPersistentTrackingInterval`, `getMaxPersistentTrackingInterval`
- diagnostics: `getSdkVersion`, `sendCustomHeartbeats`
- notification: `setIntentForNotification`, `clearIntentForNotification`
- accident/passive: `setAccidentDetectionEnabled`, `isAccidentDetectionEnabled`, `setAccidentDetectionMode`, `getAccidentDetectionSettings`, `resetAccidentDetectionSettings`, `isPassiveDetectionEnabled`, `setPassiveDetectionEnabled`
- optional RTD only when requested: `getRTDManager`, `isRtdEnabled`

`TelematicsEventsRepository` owns callbacks/listeners/receivers:

- tracking state callbacks: `registerCallback`, `unregisterCallback` using `TrackingStateListener.onStartTracking()` and `onStopTracking()`
- in-process location callbacks: `setLocationListener`, `getLocationListener` using `LocationListener.onLocationChanged(location: Location?)`
- broadcast-style tracking events: `registerTrackingEventsReceiver`, `unregisterTrackingEventsReceiver` using `TrackingEventsReceiver`
- optional speed violation callbacks/thresholds when requested: `registerSpeedViolations`, `unregisterSpeedViolations`, `isSpeedViolationsRegistered`, `setSpeedLimit`, `setSpeedLimitTimeout`, `getSpeedLimit`, `getTimeouts`

`TrackingEventsReceiver` receives `onLocationChanged`, `onStartTracking`, `onStopTracking`, `onSpeedViolation`, `onNewEvents`, and `onSdkDeprecated`.

Do not wrap SDK internal manifest receivers such as boot/keep-alive receivers; they are declared by the SDK library manifest and are not app extension points.

`TelematicsTagsRepository` owns tags:

- processed trip tags: `getTrackTags`, `addTrackTags`, `removeTrackTags`
- future tags: `getFutureTrackTags`, `addFutureTrackTag`, `removeFutureTrackTag`, `removeAllFutureTrackTags`
- tag callbacks/receivers: `registerTagsReceiver`, `unregisterTagsReceiver`, `addTagsProcessingCallback`, `removeTagsProcessingCallback`, `getTagsProcessingCallback`

`TagsProcessingListener` / `TagsProcessingReceiver` callbacks include `onTagAdd`, `onTagRemove`, `onAllTagsRemove`, and `onGetTags`.

`TelematicsTripsRepository` owns trips/statistics/share:

- trips: `getTracks`, `getTrackDetails`, `getUnsentTrips`, `getUnsentTripCount`, `uploadUnsentTrips`
- origin: `getTrackOriginDict`, `changeTrackOrigin`
- dashboard/statistics: `getMainStatistics`, `getDrivingDetailsStatistics`, `getDrivingTimeDetailsStatistics`, `getSpeedDetailStatistics`, `getMileageDetailsStatistics`, `getPhoneDetailStatistics`
- sharing: `shareTrack`, `getSharedTrackDetails`

Avoid deprecated SDK methods in new repositories: `startPersistentTracking`, `setDisableWithUpload`, `getUnsentTracks`, `getUnsentTracksCount`, `getDashboardInfo`.

## Trips, Tags, Diagnostics, And Extras

Trip/origin/statistics methods include:

- `getTracks(locale, startDate, endDate, offset, count): Array<Track>`
- `getTrackDetails(trackId, locale): TrackDetails`
- `getTrackTags(trackId): Array<TrackTag>`
- `addTrackTags(trackId, tags): Array<TrackTag>`
- `removeTrackTags(trackId, tags): Array<TrackTag>`
- `getUnsentTracks()`, `getUnsentTrips()`
- `getUnsentTracksCount()`, `getUnsentTripCount()`
- `uploadUnsentTrips()`
- `getTrackOriginDict(locale)`
- `changeTrackOrigin(trackToken, newCode)`
- dashboard/statistics methods
- `shareTrack(trackToken, isShared)`
- `getSharedTrackDetails(trackToken)`

Do not call blocking trip/statistics APIs on the main thread.

Future tag methods:

- `getFutureTrackTags()`
- `addFutureTrackTag(tag: String?, source: String? = null)`
- `removeFutureTrackTag(tag: String?)`
- `removeAllFutureTrackTags()`

Results are delivered through `TagsProcessingListener` or `TagsProcessingReceiver`; do not assume these methods return tag success synchronously.

Accident/passive APIs:

- `setAccidentDetectionEnabled(enabled)`
- `isAccidentDetectionEnabled()`
- `setAccidentDetectionMode(sensitivity)`
- `getAccidentDetectionSettings()`
- `resetAccidentDetectionSettings()`
- `isPassiveDetectionEnabled()`
- `setPassiveDetectionEnabled(enabled)`

Speed violation APIs require product-specific values:

- `registerSpeedViolations(speed, timeout, listener)`
- `unregisterSpeedViolations()`
- `isSpeedViolationsRegistered()`
- `setSpeedLimit(speedLimitKmH)`
- `setSpeedLimitTimeout(speedLimitTimeoutMs)`

Do not add speed-limit behavior by default.
