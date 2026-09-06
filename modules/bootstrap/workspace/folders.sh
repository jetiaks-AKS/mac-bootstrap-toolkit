#!/bin/bash

# ==========================================
# Workspace Folders Bootstrap
# ==========================================

bootstrap_workspace_folders() {

    if blueprint_exists &&
       [[ -z "$(blueprint_selected_items workspace-folders)" ]]; then
        success "No Workspace folders selected by Blueprint"
        return 0
    fi

    action "Creating Workspace folders..."

    local config_file
    config_file="$(blueprint_generated_file workspace-folders)"

    local folders folder
    if ! folders="$(workspace_read_bootstrap_folders "$config_file")"; then
        error "Workspace folders configuration is missing, unreadable, or not actionable"
        return 2
    fi

    while IFS= read -r folder; do
        [[ -n "$folder" ]] || continue

if [[ ! -d "$HOME/$folder" ]]; then

    action "Creating: $folder"

        if ! mkdir -p "$HOME/$folder"; then

            error "Failed to create workspace folder: $folder"
            return 2

        fi

    fi

    done <<< "$folders"

    success "Workspace configuration loaded"

    return 0

}
