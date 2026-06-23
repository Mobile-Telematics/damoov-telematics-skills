# AGENTS.md - Public Guidance for Damoov Telematics Skills

This repository contains AI agent skills for developers integrating Damoov products.

## How Agents Should Use This Repository

- Treat each `SKILL.md` as executable guidance for coding tasks.
- Load a skill only when the user's request matches its `name` or `description`.
- Load referenced files from the skill's local `references/` directory only when the
  skill instructs you to do so.
- Prefer the repository's existing integration patterns over inventing new wrappers.
- Verify the target application's actual SDK or API usage before editing code.

## Skill Areas

- `skills/damoov-telematics-skill/` - top-level routing skill.
- `skills/mobile/` - Telematics SDK integration for mobile applications.
- `skills/backend/` - Backend registration, DeviceToken, hierarchy, JWT, user management, product management, trips, and statistics flows.
- `skills/testing/` - Test user creation and integration validation flows.

## Security Rules

- Never expose `InstanceKey` in mobile applications.
- Never commit real credentials, JWTs, DeviceTokens, customer identifiers, or API secrets.
- Use placeholders such as `<InstanceId>`, `<InstanceKey>`, `<DeviceToken>`, `<admin-jwt>`,
  and `<user-jwt>` in examples.
- Keep customer-specific configuration in environment variables, CI secrets, or a secret
  manager.

## Public Scope

This public package contains runtime guidance for customers and coding agents. It intentionally
does not include internal development workflow, review notes, handoffs, tickets, or test
credentials.
