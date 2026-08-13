#!/bin/bash

# ==========================================
# Apply VS Code Settings
# ==========================================

apply_vscode_settings() {

    local source_file="config/generated/vscode/settings.json"
    local target_dir="$HOME/Library/Application Support/Code/User"
    local target_file="$target_dir/settings.json"

    if [[ ! -f "$source_file" ]]; then

        warning "Configuration file $source_file not found"
        return 1

    fi

    if ! mkdir -p "$target_dir"; then

        error "Failed to create VS Code settings directory"
        return 2

    fi

    if [[ -f "$target_file" ]]; then

        if cmp -s "$source_file" "$target_file"; then

            success "VS Code Settings already configured"
            return 0

        fi

        action "Creating backup of current VS Code Settings..."

        if ! cp "$target_file" "$target_file.bootstrap.bak"; then

            error "Failed to back up current VS Code Settings"
            return 2

        fi

    fi

    if ! cp "$source_file" "$target_file"; then

        error "Failed to apply VS Code Settings"
        return 2

    fi

    success "VS Code Settings applied successfully"

    return 0

}
