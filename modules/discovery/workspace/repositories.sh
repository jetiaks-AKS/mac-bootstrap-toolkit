#!/bin/bash

# ==========================================
# Repository Helpers
# ==========================================

get_repository_remote() {

    local repository_path="$1"
    local remotes

    remotes="$(git -C "$repository_path" remote 2>/dev/null)" || return 2

    if ! grep -Fxq origin <<< "$remotes"; then
        return 1
    fi

    git -C "$repository_path" remote get-url origin 2>/dev/null || return 2

}

get_repository_current_branch() {

    git -C "$1" symbolic-ref --quiet --short HEAD 2>/dev/null

    local result=$?
    [[ $result -eq 1 ]] && return 1
    [[ $result -eq 0 ]] && return 0
    return 2

}

get_repository_default_branch() {

    local repository_path="$1"
    local head_ref

    head_ref="$(git -C "$repository_path" symbolic-ref --quiet --short \
        refs/remotes/origin/HEAD 2>/dev/null)"

    local result=$?
    [[ $result -eq 1 ]] && return 1
    [[ $result -eq 0 ]] || return 2

    printf '%s\n' "${head_ref#origin/}"

}

get_repository_status() {

    local status_output

    status_output="$(git -C "$1" status --porcelain 2>/dev/null)" || return 2

    if [[ -n "$status_output" ]]; then
        echo "true"
    else
        echo "false"
    fi

}

# ==========================================
# Workspace Repositories Discovery
# ==========================================

export_workspace_repositories() {

    action "Exporting Git Repositories..."

    local output_file="$1"
    local folders_file="$2"
    local working_dir="$3"

    if [[ ! -f "$folders_file" || ! -r "$folders_file" ]]; then
        error "Workspace Folders are unavailable for repository discovery"
        return 2
    fi

    : > "$output_file" || {
        error "Failed to prepare Git Repositories"
        return 2
    }

    local repo_count=0
    local identifiers_file="$working_dir/repository-identifiers"

    : > "$identifiers_file" || return 2

    while IFS="|" read -r folder type; do

        [[ "$type" != "workspace" ]] && continue

        local workspace_path="$HOME/$folder"

        [[ ! -d "$workspace_path" ]] && continue

        local repositories_list="$working_dir/repositories.$repo_count"

        if ! find "$workspace_path" -type d -name ".git" > "$repositories_list" 2>/dev/null; then
            error "Failed to scan Git repositories in: $folder"
            return 2
        fi

        while IFS= read -r git_dir; do

            [[ -z "$git_dir" ]] && continue

            local repo_path repo_name
            local remote current_branch default_branch has_changes
            local has_vscode_folder has_settings has_tasks has_launch has_extensions

            if ! repo_path="$(dirname "$git_dir")" ||
               ! repo_name="$(basename "$repo_path")"; then
                error "Failed to identify Git repository"
                return 2
            fi

            if grep -Fxq -- "$repo_name" "$identifiers_file"; then
                error "Duplicate Workspace repository identifier: $repo_name"
                return 2
            fi

            printf '%s\n' "$repo_name" >> "$identifiers_file" || return 2

            remote="$(get_repository_remote "$repo_path")"
            local metadata_result=$?
            if [[ $metadata_result -eq 1 ]]; then
                remote=""
            elif [[ $metadata_result -ne 0 ]]; then
                error "Failed to read Git repository origin: $repo_name"
                return 2
            fi

            current_branch="$(get_repository_current_branch "$repo_path")"
            metadata_result=$?
            if [[ $metadata_result -eq 1 ]]; then
                current_branch=""
            elif [[ $metadata_result -ne 0 ]]; then
                error "Failed to read Git repository branch: $repo_name"
                return 2
            fi

            default_branch="$(get_repository_default_branch "$repo_path")"
            metadata_result=$?
            if [[ $metadata_result -eq 1 ]]; then
                default_branch=""
            elif [[ $metadata_result -ne 0 ]]; then
                error "Failed to read Git repository default branch: $repo_name"
                return 2
            fi

            has_changes="$(get_repository_status "$repo_path")" || {
                error "Failed to read Git repository status: $repo_name"
                return 2
            }

            has_vscode_folder="false"
            has_settings="false"
            has_tasks="false"
            has_launch="false"
            has_extensions="false"

            if [[ -d "$repo_path/.vscode" ]]; then

                has_vscode_folder="true"

                [[ -f "$repo_path/.vscode/settings.json" ]] && has_settings="true"
                [[ -f "$repo_path/.vscode/tasks.json" ]] && has_tasks="true"
                [[ -f "$repo_path/.vscode/launch.json" ]] && has_launch="true"
                [[ -f "$repo_path/.vscode/extensions.json" ]] && has_extensions="true"

            fi

            if ! cat >> "$output_file" <<EOF
[$repo_name]
NAME="$repo_name"
PATH="$repo_path"
REMOTE="$remote"
DEFAULT_BRANCH="$default_branch"
CURRENT_BRANCH="$current_branch"
HAS_UNCOMMITTED_CHANGES="$has_changes"
HAS_VSCODE_FOLDER="$has_vscode_folder"
HAS_SETTINGS="$has_settings"
HAS_TASKS="$has_tasks"
HAS_LAUNCH="$has_launch"
HAS_EXTENSIONS="$has_extensions"

EOF
            then
                error "Failed to serialize Git Repositories"
                return 2
            fi

            if [[ "$VERBOSE" == true ]]; then

                detail "Repository: $repo_name"
                detail "Path: $repo_path"
                detail "Remote: ${remote:-none}"
                detail "Current branch: ${current_branch:-none}"
                detail "Default branch: ${default_branch:-none}"
                detail "Uncommitted changes: $has_changes"
                detail "VS Code folder: $has_vscode_folder"

            fi

            ((repo_count++))

        done < "$repositories_list"

    done < "$folders_file"

    return 0

}
