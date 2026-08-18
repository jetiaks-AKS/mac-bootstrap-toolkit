#!/bin/bash

# ==========================================
# Workspace Discovery
# ==========================================

source modules/discovery/workspace/workspace.sh
source modules/discovery/workspace/folders.sh
source modules/discovery/workspace/repositories.sh
source modules/discovery/workspace/vscode.sh
source modules/discovery/workspace/inventory.sh

# ==========================================
# Workspace Snapshot Validation
# ==========================================

workspace_validate_folders() {

    local folders_file="$1"

    awk -F '|' '
        NF != 2 || $1 == "" || ($2 != "system" && $2 != "user" && $2 != "workspace") {
            exit 2
        }
    ' "$folders_file"

}

workspace_validate_repositories() {

    local repositories_file="$1"

    awk '
        BEGIN {
            keys["NAME"] = 1
            keys["PATH"] = 1
            keys["REMOTE"] = 1
            keys["DEFAULT_BRANCH"] = 1
            keys["CURRENT_BRANCH"] = 1
            keys["HAS_UNCOMMITTED_CHANGES"] = 1
            keys["HAS_VSCODE_FOLDER"] = 1
            keys["HAS_SETTINGS"] = 1
            keys["HAS_TASKS"] = 1
            keys["HAS_LAUNCH"] = 1
            keys["HAS_EXTENSIONS"] = 1

            boolean_keys["HAS_UNCOMMITTED_CHANGES"] = 1
            boolean_keys["HAS_VSCODE_FOLDER"] = 1
            boolean_keys["HAS_SETTINGS"] = 1
            boolean_keys["HAS_TASKS"] = 1
            boolean_keys["HAS_LAUNCH"] = 1
            boolean_keys["HAS_EXTENSIONS"] = 1
        }

        function validate_section(    key) {
            if (section == "") return
            for (key in keys) if (!seen_key[key]) exit 2
        }

        /^[[:space:]]*$/ { next }

        /^\[[^]]+\]$/ {
            validate_section()
            section = substr($0, 2, length($0) - 2)
            if (seen_section[section]++) exit 2
            for (key in seen_key) delete seen_key[key]
            next
        }

        {
            separator = index($0, "=")
            key = separator ? substr($0, 1, separator - 1) : ""
            value = separator ? substr($0, separator + 1) : ""

            if (section == "" || !(key in keys) || seen_key[key]++ ||
                value !~ /^".*"$/) exit 2

            if ((key in boolean_keys) && value != "\"true\"" && value != "\"false\"") {
                exit 2
            }
        }

        END {
            validate_section()
        }
    ' "$repositories_file"

}

# ==========================================
# Workspace Snapshot Publication
# ==========================================

workspace_publish_member() {

    mv "$1" "$2"

}

workspace_publish_snapshot() {

    local staging_dir="$1"
    local output_dir="$2"
    local backup_dir
    local file
    local index
    local rollback_result=0
    local -a snapshot_files=(
        folders.conf
        repositories.conf
        vscode-workspaces.conf
        inventory.conf
    )
    local -a existed_before=()

    backup_dir="$(mktemp -d "$output_dir/.snapshot-backup.XXXXXX")" || return 2

    for file in "${snapshot_files[@]}"; do
        if [[ -e "$output_dir/$file" ]]; then
            existed_before+=(true)
            if ! cp -p "$output_dir/$file" "$backup_dir/$file"; then
                rm -rf "$backup_dir" "$staging_dir"
                return 2
            fi
        else
            existed_before+=(false)
        fi
    done

    for file in "${snapshot_files[@]}"; do
        if ! workspace_publish_member "$staging_dir/$file" "$output_dir/$file"; then
            for ((index = 0; index < ${#snapshot_files[@]}; index++)); do
                file="${snapshot_files[$index]}"

                if [[ "${existed_before[$index]}" == true ]]; then
                    cp -p "$backup_dir/$file" "$output_dir/$file" || rollback_result=2
                else
                    rm -f "$output_dir/$file" || rollback_result=2
                fi
            done

            rm -rf "$backup_dir" "$staging_dir"

            if [[ $rollback_result -ne 0 ]]; then
                error "Failed to roll back Workspace generated snapshot"
            fi

            return 2
        fi
    done

    if ! rm -rf "$backup_dir" "$staging_dir"; then
        warning "Workspace snapshot published, but temporary cleanup failed"
        return 1
    fi

    return 0

}

# ==========================================
# Workspace Dependency Snapshot
# ==========================================

export_workspace_snapshot() {

    local output_dir="config/generated/workspace"
    local staging_dir
    local folder_count
    local repository_count
    local vscode_workspace_count
    local publication_result

    if ! mkdir -p "$output_dir"; then
        error "Failed to prepare Workspace generated directory"
        return 2
    fi

    staging_dir="$(mktemp -d "$output_dir/.snapshot-stage.XXXXXX")" || {
        error "Failed to create Workspace snapshot staging directory"
        return 2
    }

    if ! export_workspace_folders "$staging_dir/folders.conf" ||
       ! workspace_validate_folders "$staging_dir/folders.conf"; then
        error "Failed to prepare Workspace Folders snapshot"
        rm -rf "$staging_dir"
        return 2
    fi

    if ! export_workspace_repositories \
        "$staging_dir/repositories.conf" "$staging_dir/folders.conf" "$staging_dir" ||
       ! workspace_validate_repositories "$staging_dir/repositories.conf"; then
        error "Failed to prepare Git Repositories snapshot"
        rm -rf "$staging_dir"
        return 2
    fi

    if ! export_vscode_workspaces \
        "$staging_dir/vscode-workspaces.conf" "$staging_dir/folders.conf" "$staging_dir"; then
        error "Failed to prepare VS Code Workspaces snapshot"
        rm -rf "$staging_dir"
        return 2
    fi

    if ! export_workspace_inventory \
        "$staging_dir/inventory.conf" \
        "$staging_dir/folders.conf" \
        "$staging_dir/repositories.conf"; then
        error "Failed to prepare Workspace Inventory snapshot"
        rm -rf "$staging_dir"
        return 2
    fi

    folder_count="$(wc -l < "$staging_dir/folders.conf" | tr -d ' ')" || {
        rm -rf "$staging_dir"
        return 2
    }
    repository_count="$(grep -c '^\[[^]]*\]$' "$staging_dir/repositories.conf")"
    [[ $? -le 1 ]] || {
        rm -rf "$staging_dir"
        return 2
    }
    vscode_workspace_count="$(grep -c '^\[[^]]*\]$' "$staging_dir/vscode-workspaces.conf")"
    [[ $? -le 1 ]] || {
        rm -rf "$staging_dir"
        return 2
    }

    workspace_publish_snapshot "$staging_dir" "$output_dir"
    publication_result=$?

    if [[ $publication_result -eq 2 ]]; then
        error "Failed to publish Workspace generated snapshot"
        return 2
    fi

    if [[ $publication_result -ne 0 && $publication_result -ne 1 ]]; then
        error "Failed to publish Workspace generated snapshot"
        return 2
    fi

    success "$folder_count folder(s) exported"
    success "$repository_count repositor$( [[ $repository_count -eq 1 ]] && echo "y" || echo "ies") exported"
    success "$vscode_workspace_count VS Code workspace(s) exported"
    success "Workspace inventory generated"

    return "$publication_result"

}

# ==========================================
# Discover Workspace
# ==========================================

discover_workspace() {

    local discovery_result=0
    local exporter_result

    export_workspace
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_workspace_snapshot
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    if [[ $discovery_result -eq 0 ]]; then
        success "Workspace Discovery completed"
    elif [[ $discovery_result -eq 1 ]]; then
        warning "Workspace Discovery completed with warnings"
    else
        error "Workspace Discovery completed with errors"
    fi

    return "$discovery_result"

}
