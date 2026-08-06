#!/bin/bash

# ==========================================
# Repository Helpers
# ==========================================

get_repository_remote() {

    git -C "$1" remote get-url origin 2>/dev/null

}

get_repository_current_branch() {

    git -C "$1" branch --show-current 2>/dev/null

}

get_repository_default_branch() {

    local head_ref

    head_ref="$(git -C "$1" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"

    basename "$head_ref"

}

get_repository_status() {

    if [[ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]]; then
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

    local output_dir="config/generated/workspace"
    local output_file="$output_dir/repositories.conf"
    local folders_file="$output_dir/folders.conf"

    mkdir -p "$output_dir"

    > "$output_file"

    local repo_count=0

    while IFS="|" read -r folder type; do

        [[ "$type" != "workspace" ]] && continue

        local workspace_path="$HOME/$folder"

        [[ ! -d "$workspace_path" ]] && continue

        while IFS= read -r git_dir; do

            local repo_path
            local repo_name

            repo_path="$(dirname "$git_dir")"
            repo_name="$(basename "$repo_path")"

            local remote
            local current_branch
            local default_branch
            local has_changes

            remote="$(get_repository_remote "$repo_path")"

            current_branch="$(get_repository_current_branch "$repo_path")"

            default_branch="$(get_repository_default_branch "$repo_path")"

            has_changes="$(get_repository_status "$repo_path")"

            cat >> "$output_file" <<EOF
            [$repo_name]

            NAME="$repo_name"

            PATH="$repo_path"

            REMOTE="$remote"

            DEFAULT_BRANCH="$default_branch"

            CURRENT_BRANCH="$current_branch"

            HAS_UNCOMMITTED_CHANGES="$has_changes"

EOF

            ((repo_count++))

        done < <(find "$workspace_path" -type d -name ".git" 2>/dev/null)

    done < "$folders_file"

    success "$repo_count repositor$( [[ $repo_count -eq 1 ]] && echo "y" || echo "ies") exported"

}
