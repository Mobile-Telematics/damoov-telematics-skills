# Damoov Indicators API — reference

Base URL: `https://api.telematicssdk.com`  
Version: **v3** (do not use v2 — incorrect endpoint versions)

---

## Critical rules (read first)

- **`TransportType` is required for all Statistics endpoints** (`Driver` or `All`). Omitting it may return incorrect data or an error.
- **`TransportType` is NOT required for Scores endpoints.**
- **`/consolidated` endpoints return `Result` as an object** (`{}`). All other endpoints return `Result` as an array (`[]`).
- **Daily breakdowns use different date field names:** Statistics uses `ReportDate`; Scores use `CalcDate`.
- **`/consolidated` endpoints are not in Swagger** — they work but are documented only via live testing.
- **User JWT endpoints** (`/indicators/v3/` without `/admin/`) never take a `UserId` param — UserId is extracted from the token automatically.
- **Date format: `YYYY-MM-DD` only** (not full ISO 8601 with time).

---

## Admin endpoints

Auth: `Authorization: Bearer <admin-jwt>`  
UserId = DeviceToken of the target user.

### GET `/indicators/admin/v3/Statistics`

Returns accumulated driving statistics for a user over a date range.

**Required params:** `UserId`, `StartDate`, `EndDate`, `TransportType`  
**Optional params:** `Tag`

```bash
curl --request GET \
     --url 'https://api.telematicssdk.com/indicators/admin/v3/Statistics?UserId=<DeviceToken>&StartDate=2026-06-01&EndDate=2026-06-20&TransportType=Driver' \
     --header 'accept: application/json' \
     --header 'authorization: Bearer <admin-jwt>'
```

**Live response (2026-06-15):**

```json
{
  "Result": [
    {
      "UserId": "00000000-0000-0000-0000-000000000000",
      "InstanceId": "00000000-0000-0000-0000-000000000000",
      "AppId": "00000000-0000-0000-0000-000000000000",
      "CompanyId": "00000000-0000-0000-0000-000000000000",
      "MileageKm": 1192.361745447044,
      "MileageMile": 740.9335886207932,
      "TripsCount": 16,
      "DriverTripsCount": 16,
      "OtherTripsCount": 0,
      "MaxSpeedKmh": 107.73999786376953,
      "MaxSpeedMileh": 66.94963467254638,
      "AverageSpeedKmh": 59.38255511736049,
      "AverageSpeedMileh": 36.9003197499278,
      "TotalSpeedingKm": 85.46239112176477,
      "TotalSpeedingMile": 53.10632984306462,
      "AccelerationsCount": 0,
      "BrakingsCount": 0,
      "CorneringsCount": 0,
      "PhoneUsageDurationMin": 0,
      "PhoneUsageMileageKm": 0,
      "PhoneUsageMileageMile": 0,
      "PhoneUsageSpeedingDurationMin": 0,
      "PhoneUsageSpeedingMileageKm": 0,
      "PhoneUsageSpeedingMileageMile": 0,
      "DrivingTime": 1121.9499999999998,
      "NightDrivingTime": 12.361332893371582,
      "DayDrivingTime": 763.839569568634,
      "RushHoursDrivingTime": 353.0733165740967,
      "PermissionsLevel": 100,
      "TrustLevel": 100
    }
  ],
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observations:**
- `Result` is an array — one element per user
- All distances and speeds are in BOTH units: `Km`/`Kmh` and `Mile`/`Mileh` — unlike trips endpoint, there is no `UnitSystem` param
- `TripsCount` = `DriverTripsCount` + `OtherTripsCount`
- `DrivingTime`, `NightDrivingTime`, `DayDrivingTime`, `RushHoursDrivingTime` — all in **minutes**
- `AppId` in response (not `ApplicationId` as in trips response) — different field names for the same concept

---

### GET `/indicators/admin/v3/Statistics/daily`

Same fields as Statistics but broken down per day. Adds `ReportDate` field.

**Required params:** `UserId`, `StartDate`, `EndDate`, `TransportType`  
**Optional params:** `Tag`

**Live response element (2026-06-16):**

```json
{
  "UserId": "...", "InstanceId": "...", "AppId": "...", "CompanyId": "...",
  "ReportDate": "2026-06-11T00:00:00",
  "MileageKm": 35.56, "MileageMile": 22.10, "TripsCount": 6,
  "DriverTripsCount": 6, "OtherTripsCount": 0,
  "MaxSpeedKmh": 88.26, "MaxSpeedMileh": 54.84,
  "AverageSpeedKmh": 35.14, "AverageSpeedMileh": 21.84,
  "TotalSpeedingKm": 5.76, "TotalSpeedingMile": 3.58,
  "AccelerationsCount": 4, "BrakingsCount": 1, "CorneringsCount": 5,
  "PhoneUsageDurationMin": 0.0, "PhoneUsageMileageKm": 0.0, "PhoneUsageMileageMile": 0.0,
  "PhoneUsageSpeedingDurationMin": 0.0, "PhoneUsageSpeedingMileageKm": 0.0, "PhoneUsageSpeedingMileageMile": 0.0,
  "DrivingTime": 73.05, "NightDrivingTime": 0.0, "DayDrivingTime": 29.11, "RushHoursDrivingTime": 44.52,
  "PermissionsLevel": 92, "TrustLevel": 92.0
}
```

> Date field: **`ReportDate`** (not `CalcDate` — that is used in Scores/daily endpoints)

---

### GET `/indicators/admin/v3/Statistics/Dates`

Returns the date range of available data for a user. Use this before Statistics/Scores requests to find the correct `EndDate`.

**Required params:** none  
**Optional params:** `UserId`

```bash
curl --request GET \
     --url 'https://api.telematicssdk.com/indicators/admin/v3/Statistics/Dates?UserId=<DeviceToken>' \
     --header 'accept: application/json' \
     --header 'authorization: Bearer <admin-jwt>'
```

**Live response (2026-06-15):**

```json
{
  "Result": [
    {
      "UserId": "00000000-0000-0000-0000-000000000000",
      "InstanceId": "00000000-0000-0000-0000-000000000000",
      "AppId": "00000000-0000-0000-0000-000000000000",
      "CompanyId": "00000000-0000-0000-0000-000000000000",
      "LatestTripDate": "2026-06-14T21:33:39-07:00",
      "LatestScoringDate": "2026-06-16T00:00:00"
    }
  ],
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observations:**
- `LatestTripDate` — ISO 8601 with timezone offset (local time of the driver)
- `LatestScoringDate` — ISO 8601 without timezone (UTC midnight). Can be ahead of `LatestTripDate` — scoring is recalculated nightly
- Call this endpoint first to determine a safe `EndDate` for Statistics/Scores queries

---

### GET `/indicators/admin/v3/Statistics/UniqueTags`

Returns unique trip tags used by a user in the given period.

**Required params:** none  
**Optional params:** `UserId`, `StartDate`, `EndDate`

**Live response (2026-06-16):**

```json
{
  "Result": {
    "UniqueTagsCount": 1,
    "UniqueTagsList": ["Business"]
  }
}
```

---

### GET `/indicators/admin/v3/Scores/safety`

Returns aggregated safety scores for a user over a date range.

**Required params:** `UserId`, `StartDate`, `EndDate`  
**Optional params:** `Tag`

```bash
curl --request GET \
     --url 'https://api.telematicssdk.com/indicators/admin/v3/Scores/safety?UserId=<DeviceToken>&StartDate=2026-06-01&EndDate=2026-06-20' \
     --header 'accept: application/json' \
     --header 'authorization: Bearer <admin-jwt>'
```

**Live response (2026-06-15):**

```json
{
  "Result": [
    {
      "UserId": "00000000-0000-0000-0000-000000000000",
      "InstanceId": "00000000-0000-0000-0000-000000000000",
      "AppId": "00000000-0000-0000-0000-000000000000",
      "CompanyId": "00000000-0000-0000-0000-000000000000",
      "AccelerationScore": 100,
      "BrakingScore": 100,
      "SpeedingScore": 63.583333333333336,
      "PhoneUsageScore": 100,
      "CorneringScore": 100,
      "SafetyScore": 81.66666666666667,
      "PermissionsLevel": 100,
      "TrustLevel": 100
    }
  ],
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observations:**
- `Result` is an array — one element per user
- Scores are **floats** (unlike per-trip scores in `/trips/get/admin/v1` which are integers)
- Fields: `AccelerationScore`, `BrakingScore`, `SpeedingScore`, `PhoneUsageScore`, `CorneringScore`, `SafetyScore`
- `PermissionsLevel` / `TrustLevel` also present

---

### GET `/indicators/admin/v3/Scores/safety/daily`

Same fields as Scores/safety but broken down per day. Adds `CalcDate` field.

**Required params:** `UserId`, `StartDate`, `EndDate`  
**Optional params:** `Tag`

**Live response element (2026-06-16):**

```json
{
  "UserId": "...", "InstanceId": "...", "AppId": "...", "CompanyId": "...",
  "CalcDate": "2026-06-10T00:00:00",
  "AccelerationScore": 70.0, "BrakingScore": 80.0, "SpeedingScore": 80.0,
  "PhoneUsageScore": 92.0, "CorneringScore": 64.0, "SafetyScore": 78.0,
  "PermissionsLevel": 92, "TrustLevel": 92.0
}
```

> Date field: **`CalcDate`** (not `ReportDate` — that is used in Statistics/daily)

---

### GET `/indicators/admin/v3/Scores/eco`

Returns aggregated eco scores for a user over a date range.

**Required params:** `UserId`, `StartDate`, `EndDate`

```bash
curl --request GET \
     --url 'https://api.telematicssdk.com/indicators/admin/v3/Scores/eco?UserId=<DeviceToken>&StartDate=2026-06-01&EndDate=2026-06-20' \
     --header 'accept: application/json' \
     --header 'authorization: Bearer <admin-jwt>'
```

**Live response (2026-06-15):**

```json
{
  "Result": [
    {
      "UserId": "00000000-0000-0000-0000-000000000000",
      "InstanceId": "00000000-0000-0000-0000-000000000000",
      "AppId": "00000000-0000-0000-0000-000000000000",
      "CompanyId": "00000000-0000-0000-0000-000000000000",
      "EcoScoreFuel": 99.92382400247452,
      "EcoScoreTyres": 100,
      "EcoScoreBrakes": 100,
      "EcoScoreDepreciation": 2.1981970618574396,
      "EcoScore": 70.26529923173756,
      "PermissionsLevel": 100,
      "TrustLevel": 100
    }
  ],
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observations:**
- Scores are floats (consistent with Safety Score)
- Fields: `EcoScoreFuel`, `EcoScoreTyres`, `EcoScoreBrakes`, `EcoScoreDepreciation`, `EcoScore`
- Field names align with per-trip `Scores.EcoFuel` / `EcoTyres` / `EcoBrakes` / `EcoDepreciation` in trips endpoint
- `EcoScore` is an aggregate of the four sub-scores

---

### GET `/indicators/admin/v3/Scores/eco/daily`

Same fields as Scores/eco but broken down per day. Adds `CalcDate` field.

**Required params:** `UserId`, `StartDate`, `EndDate`

**Live response element (2026-06-16):**

```json
{
  "UserId": "...", "InstanceId": "...", "AppId": "...", "CompanyId": "...",
  "CalcDate": "2026-06-10T00:00:00",
  "EcoScoreFuel": 96.80, "EcoScoreTyres": 100.0, "EcoScoreBrakes": 82.88,
  "EcoScoreDepreciation": 26.54, "EcoScore": 74.72,
  "PermissionsLevel": 92, "TrustLevel": 92.0
}
```

---

### GET `/indicators/admin/v3/Streaks`

Returns driving streaks for a user.

**Required params:** `UserId`

**Live response (2026-06-16):**

```json
{ "Result": [], "Status": 200 }
```

> Empty array for a test user. Element structure is unknown — no live data available.

---

## Consolidated (hierarchy-level) endpoints

Auth: `Authorization: Bearer <admin-jwt>`  
Filter by exactly ONE of: `CompanyId`, `AppId`, or `InstanceId` (not UserId).  
Unused hierarchy levels appear as `null` in the response.

> **Not in Swagger.** Endpoints work and are verified via live testing (2026-06-16).

### GET `/indicators/admin/v3/Scores/safety/consolidated`

**Required params:** `CompanyId` | `AppId` | `InstanceId`, `StartDate`, `EndDate`

```bash
curl -X GET \
  'https://api.telematicssdk.com/indicators/admin/v3/Scores/safety/consolidated?CompanyId=<CompanyId>&StartDate=2026-06-01&EndDate=2026-06-20' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>'
```

**Live response (2026-06-16):**

```json
{
  "Result": {
    "InstanceId": null,
    "AppId": null,
    "CompanyId": "00000000-0000-0000-0000-000000000000",
    "AccelerationScore": 75.82531175924971,
    "BrakingScore": 76.29073482428115,
    "SpeedingScore": 76.1738637534783,
    "PhoneUsageScore": 88.04318252086983,
    "CorneringScore": 85.55652890858498,
    "SafetyScore": 75.9217767700711,
    "PermissionsLevel": 93,
    "TrustLevel": 93.0
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

**Key observation:** `Result` is an **object** (not an array) — unlike user-level safety score where it is an array.

---

### GET `/indicators/admin/v3/Scores/eco/consolidated`

**Required params:** `CompanyId` | `AppId` | `InstanceId`, `StartDate`, `EndDate`

Same response shape as safety/consolidated but with eco score fields.

---

### GET `/indicators/admin/v3/Statistics/consolidated`

**Required params:** `CompanyId` | `AppId` | `InstanceId`, `StartDate`, `EndDate`, `TransportType`

**Live response (2026-06-16):**

```json
{
  "Result": {
    "InstanceId": null, "AppId": null, "CompanyId": "00000000-0000-0000-0000-000000000000",
    "TotalRegisteredUsers": 143, "ActiveUsers": 573,
    "MileageKm": 456329.74, "MileageMile": 283563.30,
    "TripsCount": 29698, "DriverTripsCount": 29698, "OtherTripsCount": 0,
    "DrivingTime": 0,
    "PermissionsLevel": 93, "TrustLevel": 93.0
  }
}
```

**Key observation:** Only `Statistics/consolidated` adds `TotalRegisteredUsers` and `ActiveUsers` — hierarchy-level metrics not present in user-level statistics.

---

## User endpoints

Auth: `Authorization: Bearer <user-jwt>`  
`UserId` is NOT a parameter — extracted from the token automatically.

| Endpoint | Required params | Optional params |
|---|---|---|
| `GET /indicators/v3/Statistics` | `StartDate`, `EndDate`, `TransportType` | `Tag` |
| `GET /indicators/v3/Statistics/daily` | `StartDate`, `EndDate`, `TransportType` | `Tag` |
| `GET /indicators/v3/Statistics/dates` | none | — |
| `GET /indicators/v3/Scores/safety` | `StartDate`, `EndDate` | `Tag` |
| `GET /indicators/v3/Scores/safety/daily` | `StartDate`, `EndDate` | `Tag` |
| `GET /indicators/v3/Scores/eco` | `StartDate`, `EndDate` | — |
| `GET /indicators/v3/Scores/eco/daily` | `StartDate`, `EndDate` | — |
| `GET /indicators/v3/Streaks` | none | — |

Response shapes are identical to admin counterparts, minus the hierarchy identity fields.

---

## Full endpoint reference table

### Admin (Admin JWT, `UserId` in query)

| HTTP | Path | Required params | Optional | Live response |
|---|---|---|---|---|
| `GET` | `/indicators/admin/v3/Statistics` | `UserId`, `StartDate`, `EndDate`, `TransportType` | `Tag` | ✅ 2026-06-15 |
| `GET` | `/indicators/admin/v3/Statistics/daily` | `UserId`, `StartDate`, `EndDate`, `TransportType` | `Tag` | ✅ 2026-06-16 |
| `GET` | `/indicators/admin/v3/Statistics/Dates` | — | `UserId` | ✅ 2026-06-15 |
| `GET` | `/indicators/admin/v3/Statistics/UniqueTags` | — | `UserId`, `StartDate`, `EndDate` | ✅ 2026-06-16 |
| `GET` | `/indicators/admin/v3/Scores/safety` | `UserId`, `StartDate`, `EndDate` | `Tag` | ✅ 2026-06-15 |
| `GET` | `/indicators/admin/v3/Scores/safety/daily` | `UserId`, `StartDate`, `EndDate` | `Tag` | ✅ 2026-06-16 |
| `GET` | `/indicators/admin/v3/Scores/eco` | `UserId`, `StartDate`, `EndDate` | — | ✅ 2026-06-15 |
| `GET` | `/indicators/admin/v3/Scores/eco/daily` | `UserId`, `StartDate`, `EndDate` | — | ✅ 2026-06-16 |
| `GET` | `/indicators/admin/v3/Streaks` | `UserId` | — | ✅ 2026-06-16 (empty) |

### Consolidated / Hierarchy (Admin JWT, `CompanyId`|`AppId`|`InstanceId` in query)

| HTTP | Path | Required params | Live response |
|---|---|---|---|
| `GET` | `/indicators/admin/v3/Scores/safety/consolidated` | `CompanyId`\|`AppId`\|`InstanceId`, `StartDate`, `EndDate` | ✅ 2026-06-16 |
| `GET` | `/indicators/admin/v3/Scores/eco/consolidated` | `CompanyId`\|`AppId`\|`InstanceId`, `StartDate`, `EndDate` | ✅ 2026-06-16 |
| `GET` | `/indicators/admin/v3/Statistics/consolidated` | `CompanyId`\|`AppId`\|`InstanceId`, `StartDate`, `EndDate`, `TransportType` | ✅ 2026-06-16 |

### User (User JWT, no `UserId` param)

| HTTP | Path | Required params | Optional |
|---|---|---|---|
| `GET` | `/indicators/v3/Statistics` | `StartDate`, `EndDate`, `TransportType` | `Tag` |
| `GET` | `/indicators/v3/Statistics/daily` | `StartDate`, `EndDate`, `TransportType` | `Tag` |
| `GET` | `/indicators/v3/Statistics/dates` | none | — |
| `GET` | `/indicators/v3/Scores/safety` | `StartDate`, `EndDate` | `Tag` |
| `GET` | `/indicators/v3/Scores/safety/daily` | `StartDate`, `EndDate` | `Tag` |
| `GET` | `/indicators/v3/Scores/eco` | `StartDate`, `EndDate` | — |
| `GET` | `/indicators/v3/Scores/eco/daily` | `StartDate`, `EndDate` | — |
| `GET` | `/indicators/v3/Streaks` | none | — |
