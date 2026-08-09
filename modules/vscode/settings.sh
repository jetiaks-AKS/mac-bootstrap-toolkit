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

    mkdir -p "$target_dir"

    if [[ -f "$target_file" ]]; then

        if cmp -s "$source_file" "$target_file"; then

            success "VS Code Settings already configured"
            return 0

        fi

        action "Creating backup of current VS Code Settings..."

        cp "$target_file" "$target_file.bootstrap.bak"

    fi

    cp "$source_file" "$target_file"

    success "VS Code Settings applied successfully"

}
