# Platform Skills

Platform skills help coding agents work with Damoov APIs for users, Applications, Instances,
trips, scores, statistics, and indicators.

## Available Skills

| Skill | Use when |
|---|---|
| [Damoov User Management](damoov-user-management-skill/) | Finding users, updating profile or service flags, deleting users, moving users between Instances, and enabling RTLD. |
| [Damoov Product Management](damoov-product-management-skill/) | Creating, reading, updating, and deleting Applications and Instances. |
| [Damoov Trips & Statistics](damoov-trips-statistics-skill/) | Fetching trips, trip details, safety scores, eco scores, statistics, daily breakdowns, and consolidated indicators. |

## Shared References

| Reference | Purpose |
|---|---|
| [Error handling](references/error-handling.md) | Common API rules for 401, 403, 422, 429, JWT refresh, and response error handling. |

## Install Only Platform Skills

```bash
npx ai-agent-skills install "$REPO" --skill damoov-user-management-skill --agent codex
npx ai-agent-skills install "$REPO" --skill damoov-product-management-skill --agent codex
npx ai-agent-skills install "$REPO" --skill damoov-trips-statistics-skill --agent codex
```

## Prompt Examples

```text
Use $damoov-user-management-skill to add an admin endpoint that finds a Damoov user by DeviceToken and updates EnableTracking.
```

```text
Use $damoov-product-management-skill to create a test Application and Instance from this backend admin tool.
```

```text
Use $damoov-trips-statistics-skill to add backend endpoints for trips, safety scores, eco scores, and driving statistics for a DeviceToken.
```

## Notes

- Use Admin JWT for admin-scoped endpoints and User JWT for user-scoped endpoints.
- Preserve documented URL casing and live response field casing exactly.
- Require explicit confirmation before destructive operations such as user, Application, or Instance deletion.
