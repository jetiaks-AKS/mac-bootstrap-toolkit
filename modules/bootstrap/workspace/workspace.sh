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
    local submodule_result

    bootstrap_workspace_folders
    submodule_result=$?

    if [[ $submodule_result -eq 2 ]]; then
        workspace_result=2
    elif [[ $submodule_result -eq 1 && $workspace_result -eq 0 ]]; then
        workspace_result=1
    fi

    echo

    bootstrap_workspace_repositories
    submodule_result=$?

    if [[ $submodule_result -eq 2 ]]; then
        workspace_result=2
    elif [[ $submodule_result -eq 1 && $workspace_result -eq 0 ]]; then
        workspace_result=1
    fi

    echo

    bootstrap_workspace_vscode
    submodule_result=$?

    if [[ $submodule_result -eq 2 ]]; then
        workspace_result=2
    elif [[ $submodule_result -eq 1 && $workspace_result -eq 0 ]]; then
        workspace_result=1
    fi

    echo

    if [[ $workspace_result -eq 0 ]]; then
        success "Workspace Bootstrap completed"
    elif [[ $workspace_result -eq 1 ]]; then
        warning "Workspace Bootstrap completed with warnings"
    else
        error "Workspace Bootstrap completed with errors"
    fi

    return "$workspace_result"

}
