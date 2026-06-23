# Backend Skills

Backend skills help coding agents implement server-side Damoov registration and auth flows.

## Available Skills

| Skill | Use when |
|---|---|
| [Damoov Backend Registration](damoov-backend-registration-skill/) | Implementing DeviceToken registration, hierarchy resolution, Admin JWT lifecycle, and secure User JWT issuance. |

## What The Backend Skill Covers

- Registering SDK users through Damoov and storing the returned DeviceToken.
- Keeping `InstanceKey` on the server side.
- Resolving Company, Application, and Instance hierarchy when dynamic routing is needed.
- Caching Admin JWT and RefreshToken correctly.
- Issuing User JWTs to authenticated mobile clients through a backend endpoint.
- Avoiding mobile-side registration secrets.

## Install Only Backend Skills

```bash
npx ai-agent-skills install "$REPO" --skill damoov-backend-registration-skill --agent codex
npx skills add "$REPO" --skill damoov-backend-registration-skill --agent codex -y
```

## Prompt Examples

```text
Use $damoov-backend-registration-skill to implement a production Damoov registration endpoint for this backend service.
```

```text
Use $damoov-backend-registration-skill to add secure User JWT issuance. The mobile app must never receive InstanceKey.
```

## Notes

- Pair this skill with `testing/damoov-integration-testing-skill` when creating validation flows.
- Pair this skill with `platform/damoov-user-management-skill` when backend code also manages existing users.
- Keep real credentials in environment variables, CI secrets, or a secret manager.
