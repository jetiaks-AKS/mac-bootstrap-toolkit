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

    local repo_path repo_name
    local remote current_branch default_branch has_changes
    local has_vscode_folder has_settings has_tasks has_launch has_extensions

    repo_path="$(dirname "$git_dir")"
    repo_name="$(basename "$repo_path")"

    remote="$(get_repository_remote "$repo_path")"
    current_branch="$(get_repository_current_branch "$repo_path")"
    default_branch="$(get_repository_default_branch "$repo_path")"
    has_changes="$(get_repository_status "$repo_path")"

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

    cat >> "$output_file" <<EOF
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

    ((repo_count++))

done < <(find "$workspace_path" -type d -name ".git" 2>/dev/null)

    done < "$folders_file"

    success "$repo_count repositor$( [[ $repo_count -eq 1 ]] && echo "y" || echo "ies") exported"

}
