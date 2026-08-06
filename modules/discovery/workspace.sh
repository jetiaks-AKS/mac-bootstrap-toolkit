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

    export_workspace

    echo

    export_workspace_folders

    echo

    export_workspace_repositories

    echo

    export_workspace_inventory

    echo



    success "Workspace Discovery completed"

}
