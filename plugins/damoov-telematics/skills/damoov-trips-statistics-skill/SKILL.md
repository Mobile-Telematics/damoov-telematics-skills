---
name: damoov-trips-statistics-skill
description: Use when fetching Damoov trips, trip details, safety or eco scores, driving statistics, daily breakdowns, consolidated indicators, and user-scoped or admin-scoped telematics analytics APIs.
---

# damoov-trips-statistics-skill

Covers: fetching trip lists, per-trip details/statistics/scores, and accumulated safety/eco indicators.

**Base URL:** `https://api.telematicssdk.com`

## Authentication

| Auth type | How to obtain |
|---|---|
| Admin JWT | `../damoov-backend-registration-skill/SKILL.md` (Step 1) or `../damoov-integration-testing-skill/references/admin-auth.md` |
| User JWT | `../damoov-backend-registration-skill/SKILL.md` "Secure User JWT issuance" section |

## Error handling quick reference

| Status | Action |
|---|---|
| `401` | JWT expired — call `POST /v1/Auth/RefreshToken`; do NOT re-login |
| `403` | Wrong JWT type — Admin JWT required for `/trips/get/admin/v1/` and `/indicators/admin/v3/`; User JWT for `/trips/get/v1/` and `/indicators/v3/` |
| `422` | Missing or invalid param — read `Errors[].Message`; check required fields (`Identifiers.UserId`, `TransportType`, date format) |
| `429` | Login rate limit hit (5/min/IP → 1h block) — use `RefreshToken`; if cold start (no token yet), wait 1 hour or use a different IP |

Full error reference: `../../shared/references/error-handling.md`.

## Never do this

- **Never** call `/trips/get/admin/v1` with a User JWT — requires Admin JWT.
- **Never** call `/trips/get/v1/` with an Admin JWT — use it only with a User JWT.
- **Never** invent field names for `Addresses.Parts` from the OpenAPI spec alone — the live response includes `Latitude`/`Longitude` which are absent from the spec.
- **Never** assume `Statistics` distance fields are in miles — they are in km when `UnitSystem = "Si"`.
- **Never** omit `Identifiers.UserId` in the admin endpoint body — the request will fail.
- **Never** use `/indicators/v2/` endpoints — correct version is **v3**.
- **Never** omit `TransportType` for Statistics endpoints — it is required; omitting it may return incorrect data.
- **Never** pass `UserId` to User JWT indicator endpoints (`/indicators/v3/`) — UserId is taken from the token automatically.
- **Never** pass `StartDate`/`EndDate` as full ISO 8601 datetimes to indicators endpoints — use `YYYY-MM-DD` date-only format.

---

## Method decision table

| Task | Endpoint | Auth | Reference |
|---|---|---|---|
| Get trips for a specific user (backend / admin context) | `POST /trips/get/admin/v1` | Admin JWT | [trips-api.md](references/trips-api.md) |
| Get trips for the authenticated user (mobile / user context) | `POST /trips/get/v1/` | User JWT | [trips-api.md](references/trips-api.md) |
| Get accumulated safety score for a specific user | `GET /indicators/admin/v3/Scores/safety` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get accumulated eco score for a specific user | `GET /indicators/admin/v3/Scores/eco` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get accumulated driving statistics for a specific user | `GET /indicators/admin/v3/Statistics` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get daily breakdown of safety scores for a user | `GET /indicators/admin/v3/Scores/safety/daily` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get daily breakdown of eco scores for a user | `GET /indicators/admin/v3/Scores/eco/daily` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get daily breakdown of driving statistics for a user | `GET /indicators/admin/v3/Statistics/daily` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get available date range for a user's data | `GET /indicators/admin/v3/Statistics/Dates` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get aggregated safety score across a company/app/instance | `GET /indicators/admin/v3/Scores/safety/consolidated` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get aggregated eco score across a company/app/instance | `GET /indicators/admin/v3/Scores/eco/consolidated` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get aggregated statistics across a company/app/instance | `GET /indicators/admin/v3/Statistics/consolidated` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get own accumulated safety score (mobile / user context) | `GET /indicators/v3/Scores/safety` | User JWT | [indicators-api.md](references/indicators-api.md) |
| Get own accumulated eco score (mobile / user context) | `GET /indicators/v3/Scores/eco` | User JWT | [indicators-api.md](references/indicators-api.md) |
| Get own accumulated driving statistics (mobile / user context) | `GET /indicators/v3/Statistics` | User JWT | [indicators-api.md](references/indicators-api.md) |
| Get unique trip tags used by a user in a date range | `GET /indicators/admin/v3/Statistics/UniqueTags` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get driving streaks for a user ⚠️ empty sample | `GET /indicators/admin/v3/Streaks` | Admin JWT | [indicators-api.md](references/indicators-api.md) |
| Get own driving streaks (mobile / user context) ⚠️ empty sample | `GET /indicators/v3/Streaks` | User JWT | [indicators-api.md](references/indicators-api.md) |

---

## Admin vs User endpoint — when to use which

### Trips

| Scenario | Endpoint |
|---|---|
| Backend service fetching data for any user by DeviceToken | `/trips/get/admin/v1` + Admin JWT |
| Mobile app showing the logged-in driver's own trips | `/trips/get/v1/` + User JWT |
| Agent has a DeviceToken and an Admin JWT | `/trips/get/admin/v1` |
| Agent has a User JWT (issued by backend via `/v1/Auth/Login`) | `/trips/get/v1/` |

### Indicators (scores / statistics)

| Scenario | Endpoint family |
|---|---|
| Backend fetching data for a specific user by DeviceToken | `/indicators/admin/v3/` + Admin JWT + `UserId` param |
| Mobile app fetching the driver's own scores | `/indicators/v3/` + User JWT (no `UserId` param) |
| Backend aggregating data across a company/app/instance | `/indicators/admin/v3/.../consolidated` + `CompanyId`\|`AppId`\|`InstanceId` |
| Need to know the latest available date before querying | `/indicators/admin/v3/Statistics/Dates` first |

---

## Trips list — quick guide

### Required fields (admin)

```json
{
  "Identifiers": { "UserId": "<DeviceToken>" },
  "StartDate": "<ISO 8601>",
  "EndDate": "<ISO 8601>"
}
```

### Optional flags

| Flag | Effect |
|---|---|
| `IncludeDetails: true` | Adds `Data.Addresses`, `Data.TransportType`, `Data.Tags`, `Data.IncomingTrackToken` |
| `IncludeStatistics: true` | Adds per-trip `Statistics` (mileage, duration, speeding, phone, hours) |
| `IncludeScores: true` | Adds per-trip `Scores` (Safety, Acceleration, Braking, Cornering, Speeding, PhoneUsage, Eco) |
| `UnitSystem: "Si"` | km; `"Imperial"` = miles |
| `Paging.IncludePagingInfo: true` | Returns `PagingInfo` object (TotalItems, TotalPages, HasNextPage) |

### Response shape

```
Result.Trips[]
  .Id                          trip UUID
  .Identifiers
    .UserId                    DeviceToken of the driver
    .ClientId                  developer's custom user ID (from UserFields.ClientId at registration)
    .CompanyId / ApplicationId / InstanceId
  .Data
    .StartDate / .EndDate      local timezone offset included (e.g. -07:00)
    .Addresses.Start / .End
      .Full                    human-readable address string
      .Parts                   CountryCode, Country, State, City, District, Street, House,
                               Latitude, Longitude
    .TransportType
      .Current                 "OriginalDriver" | other transport types
      .ConfirmNeeded           bool
      .IsChanged               bool
    .Tags                      array (empty if no trip tags set)
    .IncomingTrackToken        SDK track token for this trip
  .Statistics
    .Mileage                   float, km (if Si)
    .DurationMinutes           float
    .AccelerationsCount / .BrakingsCount / .CorneringsCount   int
    .TotalSpeedingMileage / .MidSpeedingMileage / .HighSpeedingMileage  float
    .PhoneUsageDurationMinutes / .PhoneUsageMileage           float
    .DayHours / .RushHours / .NightHours                      float (minutes driven in each period)
    .AverageSpeed / .MaxSpeed  float, km/h (if Si)
  .Scores
    .Safety / .Acceleration / .Braking / .Cornering / .Speeding / .PhoneUsage   int 0–100
    .Eco                       int 0–100 (aggregate of EcoBrakes, EcoDepreciation, EcoFuel, EcoTyres)
    .EcoBrakes / .EcoDepreciation / .EcoFuel / .EcoTyres      int 0–100

Result.PagingInfo
  .HasPreviousPage / .HasNextPage   bool
  .TotalItems / .TotalPages / .CurrentPage   int
```

Full curl and live response: [references/trips-api.md](references/trips-api.md)

---

## Indicators — quick guide

Full curl, live responses, and complete endpoint table: [references/indicators-api.md](references/indicators-api.md)

### Required parameters by endpoint type

| Endpoint type | Required params | Notes |
|---|---|---|
| Statistics (admin) | `UserId`, `StartDate`, `EndDate`, **`TransportType`** | `TransportType`: `Driver` or `All` |
| Statistics/daily (admin) | `UserId`, `StartDate`, `EndDate`, **`TransportType`** | Returns array with `ReportDate` per element |
| Statistics/Dates (admin) | — | Optional `UserId`; returns `LatestTripDate` and `LatestScoringDate` |
| Scores/safety (admin) | `UserId`, `StartDate`, `EndDate` | Optional `Tag` |
| Scores/eco (admin) | `UserId`, `StartDate`, `EndDate` | — |
| Scores/safety/daily, eco/daily | `UserId`, `StartDate`, `EndDate` | Returns array with `CalcDate` per element |
| .../consolidated | `CompanyId`\|`AppId`\|`InstanceId`, `StartDate`, `EndDate` | Statistics/consolidated also requires `TransportType` |
| User JWT variants (`/v3/`) | `StartDate`, `EndDate` (+ `TransportType` for Statistics) | No `UserId` param |

### Date format

Always `YYYY-MM-DD` — not full ISO 8601. Example: `2026-06-01`.

### Response shape differences

| Endpoint | `Result` type | Date field (daily) |
|---|---|---|
| Any user/daily endpoint | Array `[]` | Statistics → `ReportDate`; Scores → `CalcDate` |
| Any `.../consolidated` endpoint | Object `{}` | — |

### Safety score fields

```
AccelerationScore, BrakingScore, SpeedingScore, PhoneUsageScore, CorneringScore, SafetyScore
PermissionsLevel, TrustLevel
```
All floats (0–100). Note: per-trip scores in `/trips/get/admin/v1` are integers — indicators scores are floats.

### Eco score fields

```
EcoScoreFuel, EcoScoreTyres, EcoScoreBrakes, EcoScoreDepreciation, EcoScore
PermissionsLevel, TrustLevel
```
`EcoScore` is an aggregate of the four sub-scores. All floats.

### Statistics fields (key ones)

```
MileageKm / MileageMile
TripsCount, DriverTripsCount, OtherTripsCount
MaxSpeedKmh / MaxSpeedMileh, AverageSpeedKmh / AverageSpeedMileh
TotalSpeedingKm / TotalSpeedingMile
AccelerationsCount, BrakingsCount, CorneringsCount
PhoneUsageDurationMin, PhoneUsageMileageKm / PhoneUsageMileageMile
DrivingTime, NightDrivingTime, DayDrivingTime, RushHoursDrivingTime  ← all in minutes
PermissionsLevel, TrustLevel
```
Distances/speeds always in both km and mile variants — no `UnitSystem` param for indicators.

### Consolidated-only extra fields (Statistics/consolidated)

```
TotalRegisteredUsers   int — total registered users in the hierarchy level
ActiveUsers            int — active users in the period
```

### Recommended call order

1. Call `GET /indicators/admin/v3/Statistics/Dates?UserId=<DeviceToken>` to get `LatestScoringDate`
2. Use `LatestScoringDate` date part as `EndDate` in Statistics/Scores requests
