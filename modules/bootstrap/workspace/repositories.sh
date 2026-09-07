#!/bin/bash

# ==========================================
# Bootstrap Workspace Repositories
# ==========================================

preview_workspace_repositories() {

    if blueprint_exists &&
       [[ -z "$(blueprint_selected_items git-repositories)" ]]; then
        return 0
    fi

    local config_file
    config_file="$(blueprint_generated_file git-repositories)"

    local repositories
    if ! repositories="$(workspace_read_bootstrap_repositories "$config_file")"; then
        error "Workspace repositories configuration is missing, unreadable, or not actionable"
        return 2
    fi

    local has_warnings=false
    local repository_result
    local repository path remote branch

    while IFS=$'\t' read -r repository path remote branch; do
        [[ -n "$repository" ]] || continue

        repository_preview "$repository" "$path" "$remote" "$branch"
        repository_result=$?
        if [[ $repository_result -eq 2 ]]; then
            error "Repository inspection failed: $repository"
            return 2
        fi
        [[ $repository_result -eq 0 ]] || has_warnings=true
    done <<< "$repositories"

    [[ "$has_warnings" == false ]] && return 0
    return 1
}

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
    local repository_result

    local repository path remote branch
    while IFS=$'\t' read -r repository path remote branch; do
        [[ -n "$repository" ]] || continue

    info "Repository: $repository"

        repository_verify "$path" "$remote" "$branch"
        repository_result=$?
        if [[ $repository_result -eq 2 ]]; then
            error "Repository inspection failed: $repository"
            return 2
        fi
        if [[ $repository_result -ne 0 ]]; then
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
