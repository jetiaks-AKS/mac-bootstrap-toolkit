#!/bin/bash


# ==========================================
# VS Code Workspace Discovery
# ==========================================

export_vscode_workspaces() {

    action "Exporting VS Code Workspaces..."

    local output_dir="config/generated/workspace"
    local output_file="$output_dir/vscode-workspaces.conf"
    local folders_file="$output_dir/folders.conf"

    mkdir -p "$output_dir"

    > "$output_file"

    local workspace_count=0

    while IFS="|" read -r folder type; do

        [[ "$type" != "workspace" ]] && continue

        local workspace_path="$HOME/$folder"

        [[ ! -d "$workspace_path" ]] && continue

        while IFS= read -r workspace_file; do

            local workspace_name

            workspace_name="$(basename "$workspace_file" .code-workspace)"

            cat >> "$output_file" <<EOF
[$workspace_name]
PATH="$workspace_file"

EOF

            ((workspace_count++))

        done < <(find "$workspace_path" -type f -name "*.code-workspace" 2>/dev/null)

    done < "$folders_file"

    success "$workspace_count VS Code workspace(s) exported"

}
