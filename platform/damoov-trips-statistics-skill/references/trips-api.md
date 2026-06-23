# Trips API — Reference

## Endpoints

| Variant | Method + URL | Auth |
|---|---|---|
| Admin (get trips for any user) | `POST https://api.telematicssdk.com/trips/get/admin/v1` | Admin JWT |
| User (get own trips) | `POST https://api.telematicssdk.com/trips/get/v1/` | User JWT |

---

## POST /trips/get/admin/v1 — Admin: get trips for a user

**Auth:** `Authorization: Bearer <admin-jwt>`

### Request body

```json
{
  "Identifiers": {
    "UserId": "<DeviceToken / UserId>"
  },
  "StartDate": "2026-06-01T10:04:14.620Z",
  "EndDate": "2026-06-20T10:04:14.620Z",
  "IncludeDetails": true,
  "IncludeStatistics": true,
  "IncludeScores": true,
  "Locale": "EN",
  "UnitSystem": "Si",
  "SortBy": "StartDateUtc",
  "Paging": {
    "Page": 1,
    "Count": 2,
    "IncludePagingInfo": true
  }
}
```

**Key request fields:**

| Field | Required | Notes |
|---|---|---|
| `Identifiers.UserId` | Yes (admin variant) | DeviceToken / UserId of the target user |
| `StartDate` / `EndDate` | Yes | ISO 8601 with timezone |
| `IncludeDetails` | No | Adds `Data.Addresses`, `Data.TransportType`, `Data.Tags`, `Data.IncomingTrackToken` |
| `IncludeStatistics` | No | Adds `Statistics` object per trip |
| `IncludeScores` | No | Adds `Scores` object per trip |
| `UnitSystem` | No | `"Si"` (km) or `"Imperial"` (mi) |
| `SortBy` | No | `"StartDateUtc"` or `"EndDateUtc"` |
| `Paging.IncludePagingInfo` | No | Set `true` to get `PagingInfo` in response |

### Minimal curl

```bash
curl --request POST \
     --url https://api.telematicssdk.com/trips/get/admin/v1 \
     --header 'accept: application/json' \
     --header 'authorization: Bearer <admin-jwt>' \
     --header 'content-type: application/json' \
     --data '{
  "Identifiers": { "UserId": "<DeviceToken>" },
  "StartDate": "2026-06-01T00:00:00.000Z",
  "EndDate": "2026-06-30T23:59:59.999Z",
  "IncludeDetails": true,
  "IncludeStatistics": true,
  "IncludeScores": true,
  "UnitSystem": "Si",
  "Paging": { "Page": 1, "Count": 10, "IncludePagingInfo": true }
}'
```

### Live response (2026-06-15)

```json
{
  "Result": {
    "Trips": [
      {
        "Id": "00000000-0000-0000-0000-000000000000",
        "DateUpdated": "2026-06-13T15:24:48+00:00",
        "Identifiers": {
          "CompanyId": "00000000-0000-0000-0000-000000000000",
          "ApplicationId": "00000000-0000-0000-0000-000000000000",
          "InstanceId": "00000000-0000-0000-0000-000000000000",
          "UserId": "00000000-0000-0000-0000-000000000000",
          "ClientId": "client-id-001"
        },
        "Data": {
          "StartDate": "2026-06-13T07:50:52-07:00",
          "EndDate": "2026-06-13T08:14:45-07:00",
          "UnitSystem": "Si",
          "Addresses": {
            "Start": {
              "Full": "Example Street 1, Example City, Example Country",
              "Parts": {
                "CountryCode": "EX",
                "Country": "Example Country",
                "State": "Example State",
                "City": "Example City",
                "District": "Example District",
                "Street": "Example Street",
                "House": "1",
                "Latitude": 0.0,
                "Longitude": 0.0
              }
            },
            "End": {
              "Full": "Example Street 2, Example City, Example Country",
              "Parts": {
                "CountryCode": "EX",
                "Country": "Example Country",
                "State": "Example State",
                "City": "Example City",
                "District": "Example District",
                "Street": "Example Street",
                "House": "2",
                "Latitude": 0.0,
                "Longitude": 0.0
              }
            }
          },
          "TransportType": {
            "Current": "OriginalDriver",
            "ConfirmNeeded": false,
            "IsChanged": false
          },
          "Tags": [],
          "IncomingTrackToken": "00000000-0000-0000-0000-000000000000"
        },
        "Statistics": {
          "Mileage": 19.952502640930497,
          "DurationMinutes": 23.883333333333333,
          "AccelerationsCount": 0,
          "BrakingsCount": 0,
          "CorneringsCount": 0,
          "TotalSpeedingMileage": 8.506075251211975,
          "MidSpeedingMileage": 0.2088596905954713,
          "HighSpeedingMileage": 2.269131701229539,
          "PhoneUsageDurationMinutes": 0,
          "PhoneUsageMileage": 0,
          "PhoneUsageWithSpeedingDurationMinutes": 0,
          "PhoneUsageWithSpeedingMileage": 0,
          "DayHours": 9.082633018493652,
          "RushHours": 14.902883529663086,
          "NightHours": 0,
          "AverageSpeed": 61.465365529060364,
          "MaxSpeed": 104.33000183105469
        },
        "Scores": {
          "Safety": 68,
          "Acceleration": 100,
          "Braking": 100,
          "Cornering": 100,
          "Speeding": 41,
          "PhoneUsage": 100,
          "Eco": 92,
          "EcoBrakes": 100,
          "EcoDepreciation": 75,
          "EcoFuel": 100,
          "EcoTyres": 100
        }
      }
    ],
    "PagingInfo": {
      "HasPreviousPage": false,
      "HasNextPage": true,
      "TotalItems": 16,
      "TotalPages": 8,
      "CurrentPage": 1
    }
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

### Key observations

- `Identifiers.ClientId` in response = developer's custom user ID set via `UserFields.ClientId` during registration — useful for cross-referencing with your own system
- `Data.Addresses.Parts` includes `Latitude` and `Longitude` (not shown in OpenAPI spec)
- `Data.IncomingTrackToken` = the SDK track token for this trip (not in OpenAPI spec)
- `Data.TransportType.Current` = `"OriginalDriver"` when unchanged; `IsChanged` is false
- `Statistics` fields are floats; distance values are in km when `UnitSystem = "Si"`
- `Scores` fields are integers 0–100
- `Scores.Eco` is an aggregate; sub-scores: `EcoBrakes`, `EcoDepreciation`, `EcoFuel`, `EcoTyres`
- `Data.StartDate` / `EndDate` include local timezone offset (e.g., `-07:00`), not always UTC
- `PagingInfo` is a top-level object inside `Result` (not inside `Trips`)
- Total trips for this user in the period: 16 (`TotalItems`), paged 2 per page

---

## POST /trips/get/v1/ — User: get own trips

**Auth:** `Authorization: Bearer <user-jwt>`

Same request body structure as admin variant, **except**:
- Omit `Identifiers.UserId` — the endpoint returns trips for the authenticated user only
- User JWT is issued by the backend via `POST /v1/Auth/Login` (DeviceToken + InstanceKey) and
  passed to the mobile app — `InstanceKey` is never stored on the device.
  See `../../backend/damoov-backend-registration-skill/SKILL.md` — "Secure User JWT issuance".

### Request body

```json
{
  "StartDate": "2026-06-01",
  "EndDate": "2026-06-16",
  "IncludeDetails": true,
  "Paging": { "Page": 1, "Count": 2 }
}
```

**Notes on request fields vs admin variant:**
- `Identifiers` — **omit entirely** (not needed, JWT identifies the user)
- `IncludeStatistics` / `IncludeScores` — **not supported** on user endpoint (no effect)
- `Locale` / `UnitSystem` / `SortBy` — accepted (same as admin)

### Live response (Gate 2 — 2026-06-16)

```json
{
  "Result": {
    "Trips": [
      {
        "Id": "00000000-0000-0000-0000-000000000000",
        "DateUpdated": "2026-06-16T14:48:30+00:00",
        "Identifiers": {
          "CompanyId": "00000000-0000-0000-0000-000000000000",
          "ApplicationId": "00000000-0000-0000-0000-000000000000",
          "InstanceId": "00000000-0000-0000-0000-000000000000",
          "UserId": "00000000-0000-0000-0000-000000000000",
          "ClientId": "client-id-001"
        },
        "Data": {
          "StartDate": "2026-06-16T15:26:58+01:00",
          "EndDate": "2026-06-16T15:30:51+01:00",
          "UnitSystem": "Si",
          "Addresses": {
            "Start": {
              "Full": "Example Street 1, Example City, Example Country",
              "Parts": {
                "CountryCode": "EX",
                "Country": "Example Country",
                "County": "Example County",
                "City": "Example City",
                "District": "Example District",
                "Street": "Example Street",
                "Latitude": 0.0,
                "Longitude": 0.0
              }
            },
            "End": {
              "Full": "Example Street 2, Example City, Example Country",
              "Parts": {
                "CountryCode": "EX",
                "Country": "Example Country",
                "County": "Example County",
                "City": "Example City",
                "District": "Example District",
                "Street": "Example Street",
                "House": "2",
                "Latitude": 0.0,
                "Longitude": 0.0
              }
            }
          },
          "TransportType": {
            "Current": "OriginalDriver",
            "ConfirmNeeded": false,
            "IsChanged": false
          },
          "Tags": [],
          "IncomingTrackToken": "00000000-0000-0000-0000-000000000000"
        }
      }
    ]
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

### Key observations (user variant vs admin variant)

| Aspect | Admin (`/trips/get/admin/v1`) | User (`/trips/get/v1/`) |
|---|---|---|
| Response key | `Result.Trips[]` | `Result.Trips[]` (same) |
| PagingInfo | `Result.PagingInfo` present | **absent** — no paging metadata returned |
| Identifiers in request | `Identifiers.UserId` required | **omit** — JWT identifies user |
| Statistics/Scores in response | present when `IncludeStatistics/IncludeScores: true` | **not returned** — use indicators endpoints |
| Without `IncludeDetails` | sparse (Id + DateUpdated + Data.UnitSystem) | same sparse structure |
| `Identifiers` in response | `CompanyId`, `ApplicationId`, `InstanceId`, `UserId`, `ClientId` | same fields |
| `Data.Addresses`, `Tags`, `IncomingTrackToken` | present with `IncludeDetails` | same |

**User JWT `ExpiresIn`:** `864000` seconds (10 days) — observed 2026-06-16. Different from
Admin JWT (86400 = 24h) and Registration AccessToken (432000 = 5 days). May vary by instance config.
