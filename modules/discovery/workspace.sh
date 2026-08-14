#!/bin/bash

# ==========================================
# Workspace Discovery
# ==========================================

source modules/discovery/workspace/workspace.sh
source modules/discovery/workspace/folders.sh
source modules/discovery/workspace/repositories.sh
source modules/discovery/workspace/vscode.sh
source modules/discovery/workspace/inventory.sh

# ==========================================
# Discover Workspace
# ==========================================

discover_workspace() {

    local discovery_result=0
    local exporter_result

    export_workspace
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_workspace_folders
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_workspace_repositories
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_vscode_workspaces
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_workspace_inventory
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    if [[ $discovery_result -eq 0 ]]; then
        success "Workspace Discovery completed"
    elif [[ $discovery_result -eq 1 ]]; then
        warning "Workspace Discovery completed with warnings"
    else
        error "Workspace Discovery completed with errors"
    fi

    return "$discovery_result"

}
