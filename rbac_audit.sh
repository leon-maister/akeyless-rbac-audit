#!/bin/bash

# 1. Define File Paths
AUTH_JSON="auth.json"
ROLES_JSON="roles.json"
OUTPUT_FILE="akeyless_rbac_audit.csv"

echo "Step 1/3: Fetching data from Akeyless..."
# Fetching the latest data
akeyless list-auth-methods > "$AUTH_JSON"
akeyless list-roles > "$ROLES_JSON"

echo "Step 2/3: Creating CSV Header..."
# Initialize CSV file with headers
printf "Auth_Method_ID,Auth_Method_Name,Auth_Method_Type,Description,Sub_Claims,Role_Name,Rule_Type,Path,Capabilities\n" > "$OUTPUT_FILE"

echo "Step 3/3: Processing data with jq..."
# Main Processing Logic
jq -r --slurpfile auths "$AUTH_JSON" '
  # Create a High-Performance Lookup Map for Auth Methods
  ($auths[0].auth_methods | 
    map({
      (.auth_method_access_id): {
        name: .auth_method_name, 
        type: .access_info.rules_type, 
        desc: (.description // "")
      }
    }) | add
  ) as $am_map |

  # Iterate through every Role in the system
  .roles[] | 
  .role_name as $r_name |
  .role_auth_methods_assoc as $assocs |

  # Handle Role Rules: If Admin, generate a virtual "Full Access" rule
  (if .rules.admin == true then 
    [{path: "/* (Admin)", capabilities: ["ALL"], type: "admin"}] 
   else 
    .rules.path_rules // [] 
   end) as $rules |

  # Iterate through Auth Methods associated with this specific Role
  ($assocs[]? // empty) |
  .auth_method_access_id as $aid |
  
  # Process Sub-Claims: Map correct field and join array values with commas
  (.auth_method_sub_claims | if . then to_entries | map("\(.key)=\(.value | join(","))") | join("; ") else "" end) as $sub_claims |

  # Retrieve Auth Method details from the Map
  ($am_map[$aid] // {name: "Unknown/Deleted", type: "Unknown", desc: ""}) as $am |

  # Iterate through each Access Rule within the Role
  $rules[] | 
  
  # Construct final array for CSV output
  [
    $aid,
    $am.name,
    $am.type,
    $am.desc,
    $sub_claims,
    $r_name,
    .type,
    .path,
    (.capabilities | join(";"))
  ] | @csv
' "$ROLES_JSON" >> "$OUTPUT_FILE"

echo "Success! Report updated with Sub-Claims: $OUTPUT_FILE"