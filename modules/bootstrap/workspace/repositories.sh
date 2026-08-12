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

    local has_warnings=false

    for repository in $repositories; do

    local path
    local remote
    local branch

    path=$(config_get "$config_file" "$repository" PATH)
    remote=$(config_get "$config_file" "$repository" REMOTE)
    branch=$(config_get "$config_file" "$repository" CURRENT_BRANCH)

    info "Repository: $repository"

        if ! repository_verify "$path" "$remote" "$branch"; then
            warning "Repository requires manual attention: $repository"
            has_warnings=true
        fi

        echo

    done

    if [[ "$has_warnings" == true ]]; then
        return 1
    fi

    return 0

}
