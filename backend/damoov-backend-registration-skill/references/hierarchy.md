# Hierarchy — Resolve InstanceId and InstanceKey from JWT

Use this reference when you have an admin JWT and need to programmatically find
InstanceId + InstanceKey for user registration (Approach C in SKILL.md).

---

## Damoov hierarchy structure

```
Company
  └── Application  (can have many per Company)
        └── Instance  (can have many per Application)
              └── Users
```

- **InstanceId + InstanceKey** are instance-level credentials.
- Every user is registered into a specific Instance.
- All three levels (Company / Application / Instance) can have separate JWT credentials.

---

## Step 1. Check JWT access level

After obtaining an admin JWT (see `admin-auth.md`), determine what level of access it carries:

```bash
curl --request GET 'https://portal-apis.telematicssdk.com/auth/permissions' \
  --header 'Authorization: Bearer <admin-jwt>'
```

Response — Instance-level credentials (most common for single-app setups):
```json
{
  "result": {
    "userId": "00000000-0000-0000-0000-000000000000",
    "isGod": false,
    "companiesPermissions": [],
    "appsPermissions": [],
    "instancesPermissions": [
      {
        "companyId": "00000000-0000-0000-0000-000000000000",
        "companyIntId": 1,
        "appId": "00000000-0000-0000-0000-000000000000",
        "appIntId": 1456,
        "instanceId": "00000000-0000-0000-0000-000000000000",
        "instanceIntId": 3662,
        "roleId": "rol_xRRLdNMLMi8WK64J"
      }
    ]
  },
  "status": 200,
  "title": "",
  "errors": []
}
```

Response — Application-level credentials (access to all instances under the app):
```json
{
  "result": {
    "userId": "00000000-0000-0000-0000-000000000000",
    "isGod": false,
    "companiesPermissions": [],
    "appsPermissions": [
      {
        "companyId": "00000000-0000-0000-0000-000000000000",
        "companyIntId": 1,
        "appId": "00000000-0000-0000-0000-000000000000",
        "appIntId": 1456,
        "roleId": "rol_xRRLdNMLMi8WK64J"
      }
    ],
    "instancesPermissions": []
  },
  "status": 200,
  "title": "",
  "errors": []
}
```

### Access level decision table

| Non-empty array | Access scope | What you can do |
|---|---|---|
| `instancesPermissions` | Instance-level | Operate on that specific Instance only |
| `appsPermissions` | Application-level | List all Instances under the Application |
| `companiesPermissions` | Company-level | List all Applications and Instances |
| all arrays empty | No permissions | API credentials are valid but account has no assigned roles; contact Damoov support |

---

## Step 2. Fetch Instances and their credentials

Use the Accounts API (`https://accounts.telematicssdk.com`).
Choose the branch based on the access level from Step 1.

**Field mapping:** Instance `Id` → `InstanceId` header; Instance `Key` → `InstanceKey` header.

---

### Branch A — Instance-level access (`instancesPermissions` non-empty)

You already have `instanceId` from the permissions response.
Call the Instances endpoint to get `Key`:

```bash
curl -X GET \
  'https://accounts.telematicssdk.com/v1/Instances/<instanceId>' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>'
```

Live response sample (Gate 2, 2026-06-12):
```json
{
  "Result": {
    "Id": "00000000-0000-0000-0000-000000000000",
    "Key": "00000000-0000-0000-0000-000000000000",
    "Name": "Example Instance",
    "Description": "Default group",
    "Status": "Active",
    "InviteCode": "EXAMPLE",
    "AppId": "00000000-0000-0000-0000-000000000000",
    "AppName": "Example Application",
    "CompanyId": "00000000-0000-0000-0000-000000000000"
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

Extract: `Result.Id` → InstanceId, `Result.Key` → InstanceKey.

---

### Branch B — Application-level access (`appsPermissions` non-empty)

You have `appId` from the permissions response.
Call the Applications endpoint with `includeInstances=true`:

```bash
curl -X GET \
  'https://accounts.telematicssdk.com/v1/Applications/<appId>?includeInstances=true' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>'
```

Live response sample (Gate 2, 2026-06-12):
```json
{
  "Result": {
    "Id": "00000000-0000-0000-0000-000000000000",
    "Name": "Example Application",
    "Description": "d",
    "Status": "Active",
    "GooglePlayLink": "...",
    "AppleStoreLink": "...",
    "Environment": "production",
    "Instances": [
      {
        "Id": "00000000-0000-0000-0000-000000000000",
        "Key": "00000000-0000-0000-0000-000000000000",
        "Name": "Example Instance",
        "Status": "Active"
      },
      {
        "Id": "00000000-0000-0000-0000-000000000000",
        "Key": "00000000-0000-0000-0000-000000000000",
        "Name": "Example Instance",
        "Status": "Active"
      }
    ]
  },
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

Extract from `Result.Instances[]`: each item's `Id` → InstanceId, `Key` → InstanceKey.
Select the target Instance by `Name` or present the list for selection.

---

### Branch C — Company-level access (`companiesPermissions` non-empty)

You have `companyId` from the permissions response.

**Step 2a.** List all Applications under the Company:

```bash
curl -X GET \
  'https://accounts.telematicssdk.com/v1/companies/<companyId>/applications' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer <admin-jwt>'
```

Live response sample (Gate 2, 2026-06-12):
```json
{
  "Result": [
    {
      "Id": "00000000-0000-0000-0000-000000000000",
      "Name": "Example Application",
      "Description": "d",
      "Status": "Active",
      "GooglePlayLink": "...",
      "AppleStoreLink": "...",
      "Environment": "production"
    }
  ],
  "Status": 200,
  "Title": "",
  "Errors": []
}
```

Note: this endpoint returns Applications **without** Instances or Keys.

**Step 2b.** For the target Application, call Branch B to get Instances + Keys:

```bash
GET https://accounts.telematicssdk.com/v1/Applications/<appId>?includeInstances=true
```

---

### Key observations from live responses

- All field names are **PascalCase**: `Id`, `Key`, `Name`, `Status`, `AppId`, etc.
- `Key` in the Instances response = InstanceKey used in Registration API and User Login
- `Status` is a string: `"Active"` (not int)
- `InviteCode` is present in the Instance detail response — this is the short invite code shown in Datahub UI, separate from `Key`
- `Environment` on Application: `"production"`, `"UAT"`, `"test"` — filter to `"production"` for live users

---

## Manual fallback — copy from Datahub UI

If programmatic resolution is not required, get credentials directly from Datahub:

1. Open Datahub → **Control Panel** → **Hierarchy Management**
2. Expand your Application → find the target Instance
3. Click the three-dot menu (⋮) on the Instance row
4. Select **Copy InstanceId** and **Copy InstanceKey**

![Hierarchy Management — Copy InstanceId/InstanceKey](hierarchy-screenshot-placeholder)

This is the recommended approach for static single-instance setups (production Approach B).
Only use the programmatic flow when you need to dynamically route users to different Instances.
