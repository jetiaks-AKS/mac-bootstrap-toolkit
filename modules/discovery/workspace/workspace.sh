#!/bin/bash

# ==========================================
# Workspace Discovery
# ==========================================

export_workspace() {

    local output_dir="config/generated/workspace"
    local output_file="$output_dir/workspace.conf"

    mkdir -p "$output_dir"

    action "Exporting Workspace..."

    cat > "$output_file" <<EOF
WORKSPACE_ROOT="$HOME"
WORKSPACE_NAME="$(basename "$HOME")"
SCAN_DATE="$(date +%F)"
EOF

    success "Workspace exported"

}
