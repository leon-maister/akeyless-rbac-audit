# Akeyless Permissions Export Tool

This tool automates the generation of a detailed CSV report mapping Akeyless Roles to their Auth Methods and Access Rules.

### 🎯 Project Goal
**To provide a clear, auditable overview of "Who has access to What" by joining Roles and Auth Methods into a single spreadsheet.**

## 📂 Core Components
| File | Function |
| :--- | :--- |
| export_permissions.sh | **Main Script**: Fetches data from Akeyless and processes it via `jq`. |
| auth_methods.json | **Temp File**: Cached list of authentication methods (slurpfile). |
| roles.json | **Temp File**: Raw export of all roles and their rules. |

## 🏗️ Processing Logic
The script performs a relational join between two datasets:
1. **Auth Map**: Creates a high-performance lookup table from `auth_methods.json`.
2. **Role Iteration**: Traverses every role and its associated access methods.
3. **Rule Flattening**: Expands every path-rule into a unique row in the CSV.

## 📊 CSV Structure
| Column | Source | Description |
| :--- | :--- | :--- |
| **Auth_Method_ID** | `$aid` | Unique Access ID (e.g., p-xxxx). |
| **Auth_Method_Name** | `$am.name` | Friendly name from the Auth Method config. |
| **Auth_Method_Type** | `$am.type` | Technical type (SAML, OIDC, AWS, etc.). |
| **Role_Name** | `$r_name` | The name of the Akeyless Role. |
| **Rule_Type** | `.type` | Usually `path-rule` or `admin`. |
| **Path** | `.path` | The secret path or object scope. |
| **Capabilities** | `.capabilities` | List of permissions (read, list, etc.). |

## 🚀 Quick Start
1. Ensure you are logged into Akeyless CLI.
2. Run the export script:
```bash
./export_permissions.sh
```
3. Open `akeyless_permissions_report.csv` in Excel or Google Sheets.

---
**Maintained by**: [leon-maister](https://github.com/leon-maister)
