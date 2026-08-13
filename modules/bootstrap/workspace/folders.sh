#!/bin/bash

# ==========================================
# Workspace Folders Bootstrap
# ==========================================

bootstrap_workspace_folders() {

    action "Creating Workspace folders..."

    local config_file="config/generated/workspace/folders.conf"

    if [[ ! -f "$config_file" || ! -r "$config_file" ]]; then

        warning "Workspace configuration not found"

        return 1

    fi

while IFS="|" read -r folder type; do

    [[ -z "$folder" ]] && continue

if [[ ! -d "$HOME/$folder" ]]; then

    action "Creating: $folder"

        if ! mkdir -p "$HOME/$folder"; then

            error "Failed to create workspace folder: $folder"
            return 2

        fi

    fi

    done < "$config_file"

    success "Workspace configuration loaded"

    return 0

}
