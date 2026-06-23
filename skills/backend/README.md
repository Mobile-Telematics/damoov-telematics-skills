# Backend Skills

Backend skills help coding agents implement server-side Damoov registration, auth, admin API,
user management, product management, trips, and statistics flows.

## Available Skills

| Skill | Use when |
|---|---|
| [Damoov Backend Registration](damoov-backend-registration-skill/) | Implementing DeviceToken registration, hierarchy resolution, Admin JWT lifecycle, and secure User JWT issuance. |
| [Damoov User Management](damoov-user-management-skill/) | Finding users, updating profile or service flags, deleting users, moving users between Instances, and enabling RTLD. |
| [Damoov Product Management](damoov-product-management-skill/) | Creating, reading, updating, and deleting Applications and Instances from backend/admin tooling. |
| [Damoov Trips & Statistics](damoov-trips-statistics-skill/) | Fetching trips, trip details, safety scores, eco scores, statistics, daily breakdowns, and consolidated indicators. |

## Shared References

| Reference | Purpose |
|---|---|
| [Error handling](references/error-handling.md) | Common API rules for 401, 403, 422, 429, JWT refresh, and response error handling. |

## What The Backend Skill Covers

- Registering SDK users through Damoov and storing the returned DeviceToken.
- Keeping `InstanceKey` on the server side.
- Resolving Company, Application, and Instance hierarchy when dynamic routing is needed.
- Caching Admin JWT and RefreshToken correctly.
- Issuing User JWTs to authenticated mobile clients through a backend endpoint.
- Avoiding mobile-side registration secrets.

## Install Only Backend Skills

```bash
npx skills add "$REPO" --skill damoov-backend-registration-skill --agent codex -y
npx skills add "$REPO" --skill damoov-user-management-skill --agent codex -y
npx skills add "$REPO" --skill damoov-product-management-skill --agent codex -y
npx skills add "$REPO" --skill damoov-trips-statistics-skill --agent codex -y
```

## Prompt Examples

```text
Use $damoov-backend-registration-skill to implement a production Damoov registration endpoint for this backend service.
```

```text
Use $damoov-backend-registration-skill to add secure User JWT issuance. The mobile app must never receive InstanceKey.
```

```text
Use $damoov-user-management-skill to add an admin endpoint that finds a user by DeviceToken and updates EnableTracking.
```

```text
Use $damoov-trips-statistics-skill to add backend endpoints for trips, safety scores, eco scores, and driving statistics.
```

## Notes

- Pair backend skills with `../testing/damoov-integration-testing-skill` when creating validation flows.
- Use `damoov-telematics-skill` for cross-area routing.
- Keep real credentials in environment variables, CI secrets, or a secret manager.
