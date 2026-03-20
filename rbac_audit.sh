#!/bin/bash

# Output CSV file name
OUTPUT_FILE="akeyless_rbac_audit.csv"

# Temporary files for JSON data
AUTH_JSON="auth_methods_temp.json"
ROLES_JSON="roles_temp.json"

echo "[*] Fetching data from Akeyless..."

# Fetching data from Akeyless CLI
akeyless list-auth-methods --json > "$AUTH_JSON"
akeyless list-roles --json > "$ROLES_JSON"

echo "[*] Processing correlations..."

# Create CSV Header with Rule_Type to distinguish similar paths
echo "Access_ID,Auth_Method_Name,Auth_Method_Type,Role_Name,Rule_Type,Path,Capabilities" > "$OUTPUT_FILE"

# Using --slurpfile for compatibility with newer jq versions
jq -r --slurpfile auths "$AUTH_JSON" '
  # Create a lookup map for Auth Methods using Access ID as key
  ($auths[0].auth_methods | map({(.auth_method_access_id): {name: .auth_method_name, type: .access_info.rules_type}}) | add) as $am_map |

  # Iterate through all roles
  .roles[] | 
  .role_name as $r_name |
  .role_auth_methods_assoc as $assocs |
  
  # Handle Admin roles (no path_rules) and regular roles
  (if .rules.admin == true then 
    [{path: "/* (Admin)", capabilities: ["ALL"], type: "admin"}] 
   else 
    .rules.path_rules // [] 
   end) as $rules |

  # Iterate through each Auth Method associated with the Role
  ($assocs[]? // empty) | 
  .auth_method_access_id as $aid |
  
  # Get Auth Method details from the map
  ($am_map[$aid] // {name: "Unknown/Deleted", type: "Unknown"}) as $am |

  # Flatten: For every Auth Method, list every Rule assigned to the Role
  $rules[] | 
  [
    $aid, 
    $am.name, 
    $am.type, 
    $r_name, 
    .type,
    .path, 
    (.capabilities | join(";"))
  ] | @csv
' "$ROLES_JSON" >> "$OUTPUT_FILE"

echo "[+] Done! Audit report saved to: $OUTPUT_FILE"

# Cleanup temporary files
rm "$AUTH_JSON" "$ROLES_JSON"