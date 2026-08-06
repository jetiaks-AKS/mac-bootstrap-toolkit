#!/bin/bash

# ==========================================
# Workspace Inventory
# ==========================================

export_workspace_inventory() {

    local output_dir="config/generated/workspace"
    local output_file="$output_dir/inventory.conf"
    local folders_file="$output_dir/folders.conf"

    mkdir -p "$output_dir"

    action "Generating Workspace Inventory..."

    local total=0
    local workspace=0
    local user=0
    local system=0
    local repositories=0

    while IFS="|" read -r folder type; do

        [[ -z "$folder" ]] && continue

        ((total++))

        case "$type" in

            workspace)
                ((workspace++))
                ;;

            user)
                ((user++))
                ;;

            system)
                ((system++))
                ;;

        esac

    done < "$folders_file"

    if [[ -f "$output_dir/repositories.conf" ]]; then

        repositories=$(grep -c '^\[' "$output_dir/repositories.conf")

    fi

    cat > "$output_file" <<EOF
TOTAL_FOLDERS=$total
WORKSPACE_FOLDERS=$workspace
USER_FOLDERS=$user
SYSTEM_FOLDERS=$system
TOTAL_REPOSITORIES=$repositories
EOF

    success "Workspace inventory generated"

}
