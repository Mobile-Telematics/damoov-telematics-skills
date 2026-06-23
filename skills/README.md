# Skills

This directory is the canonical runtime root for Damoov Telematics skills.

| Area | Path | Purpose |
|---|---|---|
| Orchestrator | `damoov-telematics-skill/` | Top-level routing skill. Start here for broad Damoov tasks. |
| Backend | `backend/` | Backend registration, user management, product management, trips, statistics, JWT, and admin API flows. |
| Mobile | `mobile/` | Native and cross-platform mobile SDK integrations plus shared mobile references. |
| Testing | `testing/` | Test DeviceToken creation and integration validation flows. |

Keep this tree intact when vendoring the repository. Skill files use relative links across sibling
folders under `skills/`.
