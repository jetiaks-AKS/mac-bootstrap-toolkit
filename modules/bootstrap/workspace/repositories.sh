#!/bin/bash

# ==========================================
# Bootstrap Workspace Repositories
# ==========================================

bootstrap_workspace_repositories() {

    action "Restoring Git repositories..."

    local config_file="config/generated/workspace/repositories.conf"

    if [[ ! -f "$config_file" ]]; then
        warning "Workspace repositories configuration not found"
        return
    fi

    local repositories

    repositories=$(config_sections "$config_file") || {
        warning "Unable to read configuration"
        return
    }

    success "Workspace repositories configuration loaded"

    echo

for repository in $repositories; do

    local path
    local remote
    local branch

    path=$(config_get "$config_file" "$repository" PATH)
    remote=$(config_get "$config_file" "$repository" REMOTE)
    branch=$(config_get "$config_file" "$repository" CURRENT_BRANCH)

    info "Repository : $repository"
    info "Path       : $path"
    info "Remote     : $remote"
    info "Branch     : $branch"

    echo

done

}
