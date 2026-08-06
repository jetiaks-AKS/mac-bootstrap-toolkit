#!/bin/bash

# ==========================================
# Workspace Bootstrap
# ==========================================

source modules/bootstrap/workspace/folders.sh
source modules/bootstrap/workspace/repositories.sh
source modules/bootstrap/workspace/vscode.sh

bootstrap_workspace() {

    bootstrap_workspace_folders

    echo

    bootstrap_workspace_repositories

    echo

    bootstrap_workspace_vscode

    echo

    success "Workspace Bootstrap completed"

}
