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

    local repositories
    if ! repositories="$(workspace_read_bootstrap_repositories "$config_file")"; then
        error "Workspace repositories configuration is missing, unreadable, or not actionable"
        return 2
    fi

    success "Workspace repositories configuration loaded"

    echo

    local has_warnings=false

    local repository path remote branch
    while IFS=$'\t' read -r repository path remote branch; do
        [[ -n "$repository" ]] || continue

    info "Repository: $repository"

        if ! repository_verify "$path" "$remote" "$branch"; then
            warning "Repository requires manual attention: $repository"
            has_warnings=true
        fi

        echo

    done <<< "$repositories"

    if [[ "$has_warnings" == true ]]; then
        return 1
    fi

    return 0

}
