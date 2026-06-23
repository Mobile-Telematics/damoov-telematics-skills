# Testing Skills

Testing skills help coding agents create and validate Damoov integration test data before
production integration work.

## Available Skills

| Skill | Use when |
|---|---|
| [Damoov Integration Testing](damoov-integration-testing-skill/) | Creating a test DeviceToken through DataHub UI, direct registration, or JWT-driven hierarchy lookup, then validating it end to end. |

## What The Testing Skill Covers

- Manual test-user creation through DataHub UI.
- Direct registration with `InstanceId` and `InstanceKey`.
- JWT-driven hierarchy lookup when the agent starts from admin credentials.
- Verifying that a DeviceToken works in mobile SDK and API flows.
- Avoiding production Instances for generated test users.

## Install Only Testing Skills

```bash
npx ai-agent-skills install "$REPO" --skill damoov-integration-testing-skill --agent codex
npx skills add "$REPO" --skill damoov-integration-testing-skill --agent codex -y
```

## Prompt Examples

```text
Use $damoov-integration-testing-skill to create a repeatable test DeviceToken flow for this repository.
```

```text
Use $damoov-integration-testing-skill to verify that this mobile app and backend are using the same registered DeviceToken.
```

## Notes

- Use dedicated test Applications or Instances for integration validation.
- Never use production Instances for generated test users.
- Keep real credentials in local or CI secrets, not in source files.
