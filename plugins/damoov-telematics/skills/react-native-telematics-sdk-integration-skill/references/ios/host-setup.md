# React Native iOS Host Setup

This reference covers iOS host app setup for `react-native-telematics`. It is based on the public plugin's iOS implementation, podspec, README, and example app. Verify the installed plugin and generated React Native iOS project before editing.

On an Expo CNG project the config plugin applies all of this during `expo prebuild`; see `../react-native/expo-config-plugin.md`. Use this file as the explanation of what it does, and as the manual path for bare React Native apps.

## Plugin Native Baseline

The verified plugin `3.1.2` uses (unchanged from `3.1.1`; the `3.1.2` release did not touch iOS):

- Podspec name `react-native-telematics-sdk`
- iOS deployment target `15.1`
- Swift `5.0`
- React Native CocoaPods integration through `install_modules_dependencies(s)`
- TelematicsSDK SPM dependency through `spm_dependency(...)`
- TelematicsSDK SPM URL `https://github.com/Mobile-Telematics/telematicsSDK-iOS-new-SPM.git`
- Exact native SDK version `7.2.0` in the podspec

The podspec fails `pod install` when the `spm_dependency` helper is unavailable:

```text
react-native-telematics requires React Native 0.83 or newer, which provides spm_dependency in react_native_pods.rb.
```

That is the real iOS floor behind the `react-native >=0.83.0` peer range. Do not patch the podspec to bypass it.

When package documentation and the installed podspec/source disagree about a native version, prefer the installed package source. The app target still needs explicit SPM linkage, for the reason described below.

## Podfile And SPM

In the app `ios/Podfile`, enable dynamic frameworks:

```ruby
use_frameworks! :linkage => :dynamic
```

Use dynamic framework linkage because the native TelematicsSDK iOS dependency is integrated through SPM as a dynamic framework. Do not switch this integration to static linkage for TelematicsSDK.

Then run:

```bash
cd ios
pod install
```

### Attach The Swift Package To The App Target

React Native's `spm_dependency(...)` helper registers the Swift package on the Pods project and attaches the product to the **CocoaPods pod target only**. CocoaPods' `Pods-<App>-frameworks.sh` embed script embeds pods, not Swift Package products. The result is an app that links successfully and then crashes at launch:

```text
Library not loaded: @rpath/TelematicsSDK.framework/TelematicsSDK
```

In a bare React Native app, add the package to the app target once in Xcode:

- Open the `.xcworkspace`
- Select the app project → **Package Dependencies** → **+**
- Package URL: `https://github.com/Mobile-Telematics/telematicsSDK-iOS-new-SPM.git`
- Product: `TelematicsSDK`
- Dependency rule: **Exact Version**, matching the installed plugin/podspec unless the user requested a specific version
- Target: the app target, not only Pods targets
- Verify under Target → **General** → **Frameworks, Libraries, and Embedded Content** that `TelematicsSDK.framework` is present and set to **Embed & Sign**

On Expo, this manual Xcode step does not survive `expo prebuild`, which regenerates `project.pbxproj`. The config plugin does it instead, through a `post_install` hook it injects into the generated Podfile (marked `@react-native-telematics-sdk spm-app-target-fix`). Do not add the package by hand there.

## Info.plist

Add required permissions and background modes in the app `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>location</string>
    <string>processing</string>
    <string>remote-notification</string>
</array>
<key>NSMotionUsageDescription</key>
<string>Please provide motion permissions.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Please provide location permissions.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Please provide always-on location permissions.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Please provide always-on location permissions.</string>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>sdk.damoov.apprefreshtaskid</string>
    <string>sdk.damoov.appprocessingtaskid</string>
</array>
```

The example app also includes Bluetooth usage descriptions and `bluetooth-central` background mode. Add these only when the product uses Bluetooth-based behavior or the installed SDK/app requires them:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>...</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>...</string>
```

Use product-specific permission strings. Do not leave demo text in production apps unless the user explicitly wants it.

## Initialization Contract

`RPEntry.initializeSDK()` in `application(_:didFinishLaunchingWithOptions:)` is mandatory and must be the first SDK call. Omitting it does not degrade quietly: the app crashes at launch with `EXC_BREAKPOINT (SIGTRAP)` inside `RPEntry.instance`'s getter, because the lifecycle forwards touch `RPEntry.instance` before any JS has run.

From plugin `3.1.1`, the JS `TelematicsSdk.initializeSdk()` call also initializes the native iOS SDK when it has not been initialized yet. Treat that as a safety net for JS-side call ordering, not as a replacement for the AppDelegate call — JS starts too late to prevent the launch crash.

Every other iOS bridge method is guarded and rejects with error code `SDK_NOT_INITIALIZED` while the SDK is uninitialized:

```text
SDK_NOT_INITIALIZED: TelematicsSDK is not initialized. Call initializeSdk() before using this method.
```

`isInitializedSdk()` is not guarded and is safe to call first when diagnosing.

## AppDelegate

Initialize SDK at launch and forward lifecycle methods. `RPEntry.initializeSDK()` must run before `RPEntry.instance` usage:

```swift
import TelematicsSDK
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    RPEntry.initializeSDK()
    RPEntry.instance.application(
      application,
      didFinishLaunchingWithOptions: launchOptions ?? [:]
    )
    return true
  }

  func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    RPEntry.instance.application(
      application,
      handleEventsForBackgroundURLSession: identifier,
      completionHandler: completionHandler
    )
  }

  func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
    RPEntry.instance.applicationDidReceiveMemoryWarning(application)
  }

  func applicationWillTerminate(_ application: UIApplication) {
    RPEntry.instance.applicationWillTerminate(application)
  }

  func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    RPEntry.instance.application(application) {
      completionHandler(.newData)
    }
  }
}
```

For SwiftUI-based iOS host apps, bridge this standard `AppDelegate` into the SwiftUI app entry point:

```swift
import SwiftUI

@main
struct ExampleApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

If the app does not use scenes, forward app active/foreground/background in `AppDelegate`:

```swift
func applicationDidEnterBackground(_ application: UIApplication) {
  RPEntry.instance.applicationDidEnterBackground(application)
}

func applicationWillEnterForeground(_ application: UIApplication) {
  RPEntry.instance.applicationWillEnterForeground(application)
}

func applicationDidBecomeActive(_ application: UIApplication) {
  RPEntry.instance.applicationDidBecomeActive(application)
}
```

## SceneDelegate

iOS 26 and newer terminate an app built against the iOS 26 or newer SDK that has not adopted the UIScene lifecycle. Once an app is scene-based, iOS stops delivering `applicationDidBecomeActive`, `applicationWillEnterForeground`, and `applicationDidEnterBackground`, so the scene forwards are the only ones that run. Detect which case applies by checking for a `SceneDelegate.swift` file or a `UIApplicationSceneManifest` entry in `Info.plist`, and add exactly one of the two forward sets.

For scene-based apps, forward scene lifecycle in `SceneDelegate`:

```swift
import TelematicsSDK
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func sceneDidBecomeActive(_ scene: UIScene) {
    RPEntry.instance.sceneDidBecomeActive(scene)
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    RPEntry.instance.sceneWillEnterForeground(scene)
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    RPEntry.instance.sceneDidEnterBackground(scene)
  }
}
```

Do not forward both scene and non-scene foreground/background methods for the same lifecycle path. On an Expo project, the config plugin performs this detection and adds exactly one set; on Expo SDK 57 with the scene lifecycle opted in, it stops `expo prebuild` with an explanatory error until the app supplies a `SceneDelegate.swift` — see `../react-native/expo-config-plugin.md`.

## iOS-Specific JS Calls

Guard iOS-only methods and listeners:

```ts
if (Platform.OS === 'ios') {
  await TelematicsSdk.setDisableTracking(false);
  const aggressive = await TelematicsSdk.isAggressiveHeartbeats();
}
```

iOS-only APIs include permission requests, wrong accuracy state, API language, aggressive heartbeats, disable tracking, low power listener, wrong accuracy listener, and RTLD collected data listener.

## Validation

After iOS changes in a bare React Native app, run:

```bash
yarn install
yarn typescript
cd ios && pod install
npx react-native run-ios
```

On an Expo CNG project, run instead:

```bash
npx expo prebuild --clean
npx expo run:ios
```

Then confirm the SDK is actually live before debugging anything else:

```ts
const initialized = await TelematicsSdk.isInitializedSdk();
```

If CocoaPods or Xcode signing is not available, explain the limitation and still run TypeScript/lint checks plus a syntax-level review of `Info.plist`, `Podfile`, `AppDelegate`, and `SceneDelegate`.
