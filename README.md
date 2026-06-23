# Damoov Telematics Skills

Agent skills for integrating Damoov Telematics SDK, backend registration flows, platform APIs,
trip/statistics APIs, and integration testing into customer applications.

These skills are written for AI coding agents such as OpenAI Codex, Claude Code, Cursor, and other
agents that can load local skill folders with `SKILL.md` files.

## Recommended Entrypoint

Use `damoov-telematics-skill` first.

It is the customer-facing orchestrator skill. It reads the user's request, chooses the right
Damoov skill or skill sequence, asks for missing information when needed, and verifies the result
against the selected target skill.

Use the lower-level skills directly only when you already know the exact area you want:
Android, iOS, Flutter, React Native, backend registration, user management, product management,
trips/statistics, or integration testing.

## Quick Start

1. Install the self-hosted Damoov Telematics plugin, or install the skills manually.
2. Ask your agent to use `damoov-telematics-skill`.
3. Describe the integration task in normal engineering terms.
4. Let the orchestrator route to the specific Damoov skill.

Example prompts:

```text
Use $damoov-telematics-skill to integrate Damoov Telematics into this Flutter app and tell me what backend data I need.
```

```text
Use $damoov-telematics-skill to add an admin endpoint that finds a Damoov user by DeviceToken and updates EnableTracking.
```

```text
Use $damoov-telematics-skill to review this repository and tell me whether the mobile SDK, backend registration, and trips APIs are wired correctly.
```

```text
Use $damoov-telematics-skill to create an end-to-end test plan for registering a DeviceToken, passing it to the mobile SDK, and validating trips.
```

If your agent does not support `$skill-name` syntax, use plain text:

```text
Use the damoov-telematics-skill for this task.
```

Do not invoke skills with CODEOWNERS handles such as `@Mobile-Telematics/mobile-sdk`.
Those handles are for review routing, not skill execution.

## Install The Self-Hosted Plugin

Use this path when your agent supports plugins. The plugin installs the same public skills and
keeps `damoov-telematics-skill` as the main entrypoint.

Replace the repository value with the public repository you publish:

```bash
REPO="Mobile-Telematics/damoov-telematics-skills"
```

Codex reads the repo marketplace from `.agents/plugins/marketplace.json`:

```bash
codex plugin marketplace add "$REPO"
```

Claude Code reads the marketplace from `.claude-plugin/marketplace.json`:

```text
/plugin marketplace add Mobile-Telematics/damoov-telematics-skills
/plugin install damoov-telematics@damoov-telematics
```

Cursor reads the marketplace from `.cursor-plugin/marketplace.json`. For team distribution, import
the public repository as a team marketplace:

```text
Dashboard -> Settings -> Plugins -> Import
Repository URL: https://github.com/Mobile-Telematics/damoov-telematics-skills
```

After installing, start with the orchestrator:

```text
Use $damoov-telematics-skill to route this Damoov integration task.
```

In Claude Code, plugin skills are namespaced. Use:

```text
/damoov-telematics:damoov-telematics-skill
```

## Public Skills

| Area | Skill folder | Use when |
|---|---|---|
| Orchestrator | `platform/damoov-telematics-skill/` | You want one entrypoint that routes Damoov tasks to the right skill. |
| Android | `mobile/android-telematics-sdk-integration-skill/` | Native Android Kotlin SDK integration, migration, review, permissions, lifecycle, tracking, tags, and trips. |
| iOS | `mobile/ios-telematics-sdk-integration-skill/` | Native iOS Swift SDK integration, SPM setup, lifecycle forwarding, background modes, tracking, and tags. |
| Flutter | `mobile/flutter-telematics-sdk-integration-skill/` | Flutter plugin integration plus Android and iOS host setup. |
| React Native | `mobile/react-native-telematics-sdk-integration-skill/` | React Native plugin integration plus Android and iOS host setup. |
| Backend | `backend/damoov-backend-registration-skill/` | Production DeviceToken registration, InstanceKey secrecy, Admin JWT lifecycle, and secure User JWT issuance. |
| User Management | `platform/damoov-user-management-skill/` | Find, update, delete, move users, and manage service flags such as `EnableTracking`. |
| Product Management | `platform/damoov-product-management-skill/` | Create, read, update, and delete Applications and Instances. |
| Trips & Statistics | `platform/damoov-trips-statistics-skill/` | Trips, trip details, safety scores, eco scores, driving statistics, daily breakdowns, and consolidated indicators. |
| Testing | `testing/damoov-integration-testing-skill/` | Test DeviceToken creation and integration validation. |

## Install All Skills Manually

Use this fallback when your agent supports skills but not plugins, or when you want Stripe-style
manual skill installation.

```bash
REPO="Mobile-Telematics/damoov-telematics-skills"
```

Install all skills for Codex:

```bash
npx ai-agent-skills install "$REPO" --agent codex
```

Install all skills for Claude Code:

```bash
npx ai-agent-skills install "$REPO" --agent claude
```

Preview without changing local files:

```bash
npx ai-agent-skills install "$REPO" --agent codex --dry-run
npx ai-agent-skills install "$REPO" --agent claude --dry-run
```

Alternative installer:

```bash
npx skills add "$REPO" --skill '*' --agent codex -y
npx skills add "$REPO" --skill '*' --agent claude-code -y
```

List available skills before installing:

```bash
npx skills add "$REPO" --list
```

## Install From A Local Clone

Install from a local checkout of the public repository:

```bash
npx ai-agent-skills install . --agent codex
npx ai-agent-skills install . --agent claude
```

Or with `skills`:

```bash
npx skills add . --skill '*' --agent codex -y
npx skills add . --skill '*' --agent claude-code -y
```

## Manual Install

Use manual install when your agent reads skill folders directly or when you vendor the skills in a
customer repository.

Keep the repository layout intact. Several skills reference shared files in sibling folders.

Codex project install:

```bash
SKILLS_SRC="$PWD/vendor/damoov-telematics-skills"
mkdir -p .agents/skills
find "$SKILLS_SRC"/backend "$SKILLS_SRC"/mobile "$SKILLS_SRC"/platform "$SKILLS_SRC"/testing \
  -mindepth 1 -maxdepth 1 -type d -name '*-skill' \
  -exec ln -sfn {} .agents/skills/ \;
```

Cursor project install:

```bash
SKILLS_SRC="$PWD/vendor/damoov-telematics-skills"
mkdir -p .cursor/skills
find "$SKILLS_SRC"/backend "$SKILLS_SRC"/mobile "$SKILLS_SRC"/platform "$SKILLS_SRC"/testing \
  -mindepth 1 -maxdepth 1 -type d -name '*-skill' \
  -exec ln -sfn {} .cursor/skills/ \;
```

Claude Code project install:

```bash
SKILLS_SRC="$PWD/vendor/damoov-telematics-skills"
mkdir -p .claude/skills
find "$SKILLS_SRC"/backend "$SKILLS_SRC"/mobile "$SKILLS_SRC"/platform "$SKILLS_SRC"/testing \
  -mindepth 1 -maxdepth 1 -type d -name '*-skill' \
  -exec ln -sfn {} .claude/skills/ \;
```

For other agents, use the equivalent project-level skills directory and symlink or copy each
`*-skill` folder.

## Install One Skill

Prefer installing all skills so `damoov-telematics-skill` can route across mobile, backend,
platform, and testing. Install one skill only for narrow environments.

Examples:

```bash
npx ai-agent-skills install "$REPO" --skill damoov-telematics-skill --agent codex
npx ai-agent-skills install "$REPO" --skill android-telematics-sdk-integration-skill --agent codex
npx ai-agent-skills install "$REPO" --skill ios-telematics-sdk-integration-skill --agent codex
npx ai-agent-skills install "$REPO" --skill flutter-telematics-sdk-integration-skill --agent codex
npx ai-agent-skills install "$REPO" --skill react-native-telematics-sdk-integration-skill --agent codex
npx ai-agent-skills install "$REPO" --skill damoov-backend-registration-skill --agent codex
npx ai-agent-skills install "$REPO" --skill damoov-user-management-skill --agent codex
npx ai-agent-skills install "$REPO" --skill damoov-product-management-skill --agent codex
npx ai-agent-skills install "$REPO" --skill damoov-trips-statistics-skill --agent codex
npx ai-agent-skills install "$REPO" --skill damoov-integration-testing-skill --agent codex
```

## Update Skills

Run the install command again after pulling a newer version:

```bash
npx ai-agent-skills install "$REPO" --agent codex
npx ai-agent-skills install "$REPO" --agent claude
```

If installed with `skills`:

```bash
npx skills update -y
npx skills update --global -y
```

## How The Orchestrator Routes Work

`damoov-telematics-skill` does not implement Damoov APIs by itself. It routes to target skills and
requires the agent to load those target skills before editing code.

Common routes:

| Request | Orchestrator route |
|---|---|
| "Integrate Damoov into this Android app" | Android SDK skill |
| "Integrate Damoov into this Flutter app" | Flutter SDK skill |
| "Register users from our backend and return User JWT" | Backend registration skill |
| "Find a user by DeviceToken and update EnableTracking" | User management skill |
| "Create an Application and Instance" | Product management skill |
| "Fetch trips and safety score" | Trips & statistics skill |
| "Create a test DeviceToken and validate the integration" | Integration testing skill |
| "Set up a full mobile + backend integration" | Backend registration -> mobile SDK skill -> integration testing |

When the request is ambiguous, the orchestrator asks the smallest routing question, for example:

```text
Which mobile stack is this: Android, iOS, Flutter, or React Native?
```

## Direct Skill Prompts

Use direct prompts when you intentionally want to bypass the orchestrator:

```text
Use $android-telematics-sdk-integration-skill to integrate Damoov TelematicsSDK into this native Android Kotlin app.
```

```text
Use $ios-telematics-sdk-integration-skill to review this iOS app for lifecycle, permissions, tracking, and tag issues.
```

```text
Use $damoov-backend-registration-skill to implement a backend endpoint that registers a Damoov user and stores the DeviceToken linked to my app user.
```

```text
Use $damoov-user-management-skill to add an admin endpoint that finds a user by DeviceToken and updates EnableTracking.
```

```text
Use $damoov-trips-statistics-skill to add backend endpoints for trips, safety scores, eco scores, and driving statistics.
```

## Repository Layout

```text
backend/    Backend registration, DeviceToken, hierarchy, and JWT skills
mobile/     Mobile SDK integration skills and shared DeviceToken/RTLD references
platform/   Orchestrator and Damoov platform API operation skills
testing/    Test user creation and integration validation skills
```

Each skill folder contains a `SKILL.md` file. Some skills also include:

- `references/` for API details, code patterns, curl examples, and verified response notes.
- `agents/` for optional agent-specific metadata.

## Local CODEOWNERS Routing

GitHub uses `.github/CODEOWNERS` during pull request review. To check the same ownership routing
locally:

```bash
scripts/codeowners-local.sh
```

Check specific paths:

```bash
scripts/codeowners-local.sh mobile/ backend/damoov-backend-registration-skill/SKILL.md
```

Current routing:

```text
mobile/   -> @Mobile-Telematics/mobile-sdk
backend/  -> @Mobile-Telematics/backend
platform/ -> @Mobile-Telematics/platform-api
testing/  -> @Mobile-Telematics/qa
```

These owners are for review routing only. They are not plugins, skills, or invocation commands.

## Credential Safety

Never commit real Damoov credentials, `InstanceKey`, Admin JWT, User JWT, DeviceToken, customer
IDs, or production identifiers into application code, tests, docs, logs, or skill files.

Use placeholders in examples:

```text
<CompanyId>
<AppId>
<InstanceId>
<InstanceKey>
<DeviceToken>
<admin-jwt>
<user-jwt>
```

Store real values in a local secret manager, CI secret store, environment variables, or your
organization's approved credential system.

## Troubleshooting

If a skill does not appear in your agent:

- Confirm the installed directory contains `SKILL.md`.
- Confirm the `SKILL.md` file has `name` and `description` frontmatter.
- Restart the agent if it does not hot-reload skills.
- Install or symlink the whole repository layout when a skill references sibling folders.
- Use an explicit prompt such as `Use $damoov-telematics-skill ...`.

If generated code looks generic:

- Ask the agent to load `damoov-telematics-skill` first.
- Ask it to name the target Damoov skill it selected.
- Ask it to cite the skill reference file it used for endpoint names, request fields, response
  fields, and SDK method names.
