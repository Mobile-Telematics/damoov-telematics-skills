---
name: damoov-telematics-skill
description: Top-level Damoov router and orchestrator. Use when a customer asks for any Damoov integration, SDK setup, DeviceToken registration, backend auth flow, user management, Application or Instance management, trips/statistics analytics, integration testing, RTD/RTLD setup, troubleshooting, review, or migration and does not know which specific Damoov skill to invoke.
---

# Damoov Skill

Use this skill as the single customer-facing entry point for Damoov work. Classify the request,
load the correct target skill or skill sequence, relay any target-skill questions to the user, and
verify the result against the selected skill rules.

## Never Do This

- Never implement from this orchestrator alone. Always load and follow the selected target
  `SKILL.md` before editing code, writing API calls, or reviewing an integration.
- Never copy endpoint tables, request fields, response fields, curl examples, or SDK API details
  into this skill. The target skills and their references are the source of truth.
- Never guess missing information that a target skill requires. Ask the user the smallest
  necessary question and wait.
- Never expose or commit real `InstanceKey`, Admin JWT, User JWT, DeviceToken, customer IDs, or
  production identifiers. Use placeholders and environment variable names.
- Never treat `@Mobile-Telematics/...` CODEOWNERS handles as skills. Use `$skill-name` routing.
- Never run destructive user/Application/Instance operations without the explicit confirmation
  required by the target skill.

## Workflow

1. Inspect the user request and, when needed, the target repository shape.
2. Select exactly one route from **Single-Skill Routing** or a sequence from **Multi-Skill Routes**.
3. State the selected route briefly before implementation.
4. Load each target skill's `SKILL.md` in dependency order and follow its required references.
5. If the target skill asks for missing information, ask the user and stop until answered.
6. Complete the work using the target skill, not this router.
7. Run the target skill's validation steps or state why they could not run.
8. Finish with the **Post-Work Validation Checklist**.

## Single-Skill Routing

| User intent or trigger terms | Load and follow |
|---|---|
| Android native app, Kotlin, Gradle, Maven, `TrackingApi`, Android permissions, Android manifest, Android SDK migration | [`android-telematics-sdk-integration-skill`](../mobile/android-telematics-sdk-integration-skill/SKILL.md) |
| iOS native app, Swift, SPM, `RPEntry`, `AppDelegate`, `SceneDelegate`, background modes, iOS SDK migration | [`ios-telematics-sdk-integration-skill`](../mobile/ios-telematics-sdk-integration-skill/SKILL.md) |
| Flutter app, `pubspec.yaml`, Flutter plugin, Dart `TrackingApi`, Flutter Android/iOS host setup | [`flutter-telematics-sdk-integration-skill`](../mobile/flutter-telematics-sdk-integration-skill/SKILL.md) |
| React Native app, TypeScript, `react-native-telematics`, native bridge, React Native Android/iOS host setup | [`react-native-telematics-sdk-integration-skill`](../mobile/react-native-telematics-sdk-integration-skill/SKILL.md) |
| Production backend registration, DeviceToken creation for app users, InstanceKey secrecy, hierarchy resolution, Admin JWT lifecycle, User JWT issuance | [`damoov-backend-registration-skill`](../backend/damoov-backend-registration-skill/SKILL.md) |
| Test DeviceToken, DataHub user creation, direct `InstanceId` + `InstanceKey` registration, JWT-driven test setup, integration verification | [`damoov-integration-testing-skill`](../testing/damoov-integration-testing-skill/SKILL.md) |
| Find, update, delete, or move existing Damoov users; `EnableTracking`, `EnableLogging`, `EnableRealTimeLocation`, `UserDeviceToken`, `GetFilteredPage` | [`damoov-user-management-skill`](../backend/damoov-user-management-skill/SKILL.md) |
| Application CRUD, Instance CRUD, hierarchy product management, status changes, destructive app/instance operations | [`damoov-product-management-skill`](../backend/damoov-product-management-skill/SKILL.md) |
| Trips, trip details, safety score, eco score, driving statistics, daily breakdown, consolidated indicators, streaks, analytics APIs | [`damoov-trips-statistics-skill`](../backend/damoov-trips-statistics-skill/SKILL.md) |

## Multi-Skill Routes

| Scenario | Load and follow in this order |
|---|---|
| New production mobile integration with backend-owned DeviceToken | Backend registration -> target mobile SDK skill -> integration testing |
| Mobile-only SDK setup when a valid DeviceToken already exists | Target mobile SDK skill -> integration testing |
| End-to-end proof of a new integration | Integration testing -> target mobile SDK skill -> trips/statistics only if analytics are requested |
| Backend endpoint to find/update a user flag such as `EnableTracking` | User management; inspect host backend patterns. Add backend registration only if auth lifecycle or DeviceToken provisioning is in scope |
| Create test Application/Instance and then register test users | Product management -> integration testing |
| Create user analytics endpoints for trips, scores, or statistics | Trips/statistics. Add backend registration only if Admin/User JWT lifecycle must be implemented |
| RTD / RTLD / Real-Time Location Data enablement | User management for the user flag -> target mobile SDK skill for callback/stream wiring -> remind that DataHub Application-level RTD enablement is manual/platform-level |
| "No trips", "No Data", emulator/simulator trip not detected | Integration testing GPS simulation guidance -> target mobile SDK skill |

When a sequence includes a "target mobile SDK skill", choose Android, iOS, Flutter, or React Native
from repository files first. If the repository does not make the platform clear, ask the user.

## Ambiguity Handling

Ask only the question needed to route safely:

| Ambiguous request | Ask |
|---|---|
| "Integrate Damoov" with no app/backend context | "Which target do you want first: Android, iOS, Flutter, React Native, backend registration, platform APIs, or integration testing?" |
| "Set up mobile SDK" but no platform is detectable | "Which mobile stack is this: Android, iOS, Flutter, or React Native?" |
| "Create/register user" | "Is this a production backend registration flow or a test DeviceToken setup?" |
| "Get user data" | "Do you need profile/service flags, or trips/scores/statistics analytics?" |
| "Enable live location" | "Do you need the backend user flag, the mobile SDK callback/stream, or both?" |
| "Delete" or other destructive operation | Ask for explicit confirmation with the exact target entity before routing to the destructive target skill |

## Propagate Target-Skill Questions

If a target skill requires a decision, ask it on behalf of that skill and do not proceed until the
user answers. Common cases:

- Mobile SDK skills may require the target platform if repository inspection is inconclusive.
- Mobile SDK skills may require the primary tracking flow before creating a reusable service,
  facade, repository, or use-case layer.
- Android may require an SDK version if adding the dependency and no current version is present.
- Testing may require the target Instance when multiple Instances are available.
- User management requires explicit confirmation before permanent user deletion.
- Product management requires explicit confirmation before destructive Application or Instance deletion.
- API work may require whether the caller has Admin JWT, User JWT, DeviceToken, InstanceId, or
  InstanceKey available. Ask for variable names/placeholders, not real secrets.

## Post-Work Validation Checklist

Before final response, verify and report:

- Selected target skill(s) were loaded and followed.
- Target skill never-rules were not violated.
- Required user questions were asked before implementation.
- No real secrets or customer identifiers were added to code, docs, tests, logs, or examples.
- API endpoint casing, request fields, response fields, enum values, and SDK method names came
  from target skill references, not guesswork.
- Required target validation commands ran, or the exact reason they could not run is stated.
- Cross-skill flows are coherent where applicable: backend DeviceToken registration -> mobile
  `setDeviceID` / `setDeviceId` -> integration testing verification.
- Destructive actions, if any, had explicit user confirmation.
- Final answer names the route used and any unresolved blocker.
