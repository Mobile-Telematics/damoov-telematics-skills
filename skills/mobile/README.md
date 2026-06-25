# Mobile Skills

Mobile skills help coding agents integrate Damoov SDK into native and cross-platform
mobile applications.

## Available Skills

| Skill | Use when |
|---|---|
| [Android Telematics SDK Integration](android-telematics-sdk-integration-skill/) | Integrating, migrating, reviewing, or debugging native Android Kotlin apps. |
| [iOS Telematics SDK Integration](ios-telematics-sdk-integration-skill/) | Integrating, migrating, reviewing, or debugging iOS apps. |
| [Flutter Telematics SDK Integration](flutter-telematics-sdk-integration-skill/) | Integrating Flutter apps, including Android and iOS host setup. |
| [React Native Telematics SDK Integration](react-native-telematics-sdk-integration-skill/) | Integrating React Native apps, including Android and iOS host setup. |

## Shared References

| Reference | Purpose |
|---|---|
| [DeviceToken flow](references/devicetoken-flow.md) | Registration and mobile handoff concepts shared by mobile integrations. |
| [RTLD flow](references/rtld-flow.md) | Real-Time Location Data enablement across DataHub, backend, and SDK callbacks. |

## Install Only Mobile Skills

```bash
npx skills add "$REPO" --skill android-telematics-sdk-integration-skill --agent codex -y
npx skills add "$REPO" --skill ios-telematics-sdk-integration-skill --agent codex -y
npx skills add "$REPO" --skill flutter-telematics-sdk-integration-skill --agent codex -y
npx skills add "$REPO" --skill react-native-telematics-sdk-integration-skill --agent codex -y
```

## Prompt Examples

```text
Use $android-telematics-sdk-integration-skill to integrate Damoov into this native Android Kotlin app. Primary flow should be automatic tracking.
```

```text
Use $ios-telematics-sdk-integration-skill to review this iOS app for lifecycle forwarding, permissions, tracking modes, and deprecated RPEntry APIs.
```

```text
Use $flutter-telematics-sdk-integration-skill to integrate Damoov SDK Flutter plugin into this Flutter app.
```

```text
Use $react-native-telematics-sdk-integration-skill to review this React Native plugin integration across Android and iOS host setup.
```

## Notes

- Do not put `InstanceKey` or backend registration secrets in mobile code.
- The SDK receives a registered DeviceToken from the app or backend flow.
- Ask the agent to verify the SDK version actually installed in the target app before changing code.
