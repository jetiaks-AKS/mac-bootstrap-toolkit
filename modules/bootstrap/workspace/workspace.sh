#!/bin/bash

# ==========================================
# Workspace Bootstrap
# ==========================================

source modules/bootstrap/workspace/folders.sh
source modules/bootstrap/workspace/repositories-helpers.sh
source modules/bootstrap/workspace/repositories.sh
source modules/bootstrap/workspace/vscode.sh

bootstrap_workspace() {

    local workspace_result=0

    bootstrap_workspace_folders

    echo

    bootstrap_workspace_repositories || workspace_result=1

    echo

    bootstrap_workspace_vscode

    echo

    if [[ $workspace_result -eq 0 ]]; then
        success "Workspace Bootstrap completed"
    else
        warning "Workspace Bootstrap completed with warnings"
    fi

    return "$workspace_result"

}
