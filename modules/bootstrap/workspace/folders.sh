#!/bin/bash

# ==========================================
# Workspace Folders Bootstrap
# ==========================================

bootstrap_workspace_folders() {

    action "Creating Workspace folders..."

    local config_file="config/generated/workspace/folders.conf"

    if [[ ! -f "$config_file" ]]; then

        warning "Workspace configuration not found"

        return

    fi

while IFS="|" read -r folder type; do

    [[ -z "$folder" ]] && continue

if [[ ! -d "$HOME/$folder" ]]; then

    action "Creating: $folder"

    mkdir -p "$HOME/$folder"

fi

done < "$config_file"

    success "Workspace configuration loaded"

}
