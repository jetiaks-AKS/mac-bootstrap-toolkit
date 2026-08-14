#!/bin/bash

# ==========================================
# VS Code Discovery
# ==========================================

export_vscode_extensions() {

    if ! command -v code >/dev/null 2>&1; then

        warning "VS Code CLI not found"
        return 1

    fi

    local output_dir="config/generated"
    local output_file="$output_dir/vscode-extensions.conf"

    mkdir -p "$output_dir"

    action "Exporting VS Code Extensions..."

    code --list-extensions | sort > "$output_file"

    local extension_count
    extension_count=$(wc -l < "$output_file" | tr -d ' ')

    if [[ "$VERBOSE" == true ]]; then

        while IFS= read -r extension; do

            [[ -n "$extension" ]] && detail "$extension"

        done < "$output_file"

    fi

    success "$extension_count Extensions exported"

}

# ==========================================

export_vscode_settings() {

    local source_file="$HOME/Library/Application Support/Code/User/settings.json"
    local output_dir="config/generated/vscode"
    local output_file="$output_dir/settings.json"

    if [[ ! -f "$source_file" ]]; then

        warning "VS Code settings not found"
        return 1

    fi

    mkdir -p "$output_dir"

    action "Exporting VS Code Settings..."

    cp "$source_file" "$output_file"

    if [[ "$VERBOSE" == true ]]; then

        detail "Source: $source_file"
        detail "Configuration saved to: $output_file"

    fi

    success "VS Code Settings exported"

}

# ==========================================

discover_vscode() {

    local discovery_result=0
    local exporter_result

    export_vscode_extensions
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_vscode_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    if [[ $discovery_result -eq 0 ]]; then
        success "VS Code Discovery completed"
    elif [[ $discovery_result -eq 1 ]]; then
        warning "VS Code Discovery completed with warnings"
    else
        error "VS Code Discovery completed with errors"
    fi

    return "$discovery_result"

}
