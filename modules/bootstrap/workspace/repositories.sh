#!/bin/bash

# ==========================================
# Bootstrap Workspace Repositories
# ==========================================

bootstrap_workspace_repositories() {

    if blueprint_exists &&
       [[ -z "$(blueprint_selected_items git-repositories)" ]]; then
        success "No Git repositories selected by Blueprint"
        return 0
    fi

    action "Restoring Git repositories..."

    local config_file
    config_file="$(blueprint_generated_file git-repositories)"

    if [[ ! -f "$config_file" || ! -r "$config_file" ]]; then
        warning "Workspace repositories configuration not found"
        return 1
    fi

    local repositories

    repositories=$(config_sections "$config_file") || {
        warning "Unable to read configuration"
        return 1
    }

    success "Workspace repositories configuration loaded"

    echo

    local has_warnings=false

    for repository in $repositories; do

        blueprint_item_selected git-repositories "$repository" || continue

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
