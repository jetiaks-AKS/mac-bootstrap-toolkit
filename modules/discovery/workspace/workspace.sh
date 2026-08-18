#!/bin/bash

# ==========================================
# Workspace Discovery
# ==========================================

serialize_workspace() {

    local output_file="$1"
    local workspace_root="$2"
    local workspace_name="$3"
    local scan_date="$4"

    printf 'WORKSPACE_ROOT="%s"\nWORKSPACE_NAME="%s"\nSCAN_DATE="%s"\n' \
        "$workspace_root" "$workspace_name" "$scan_date" > "$output_file" || return 2

}

# ==========================================

export_workspace() {

    local output_dir="config/generated/workspace"
    local output_file="$output_dir/workspace.conf"

    action "Exporting Workspace..."

    local workspace_name
    local scan_date

    if ! workspace_name="$(basename "$HOME")" ||
       ! scan_date="$(date +%F)"; then
        error "Failed to collect Workspace metadata"
        return 2
    fi

    if ! discovery_publish_file \
        "$output_file" serialize_workspace "$HOME" "$workspace_name" "$scan_date"; then
        error "Failed to publish Workspace metadata"
        return 2
    fi

    success "Workspace exported"

    return 0

}
