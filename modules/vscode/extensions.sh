#!/bin/bash

# ==========================================
# Check VS Code CLI
# ==========================================

check_vscode_cli() {

    if command -v code >/dev/null 2>&1; then
        return 0
    fi

    warning "The 'code' command is not available"
    return 1

}

# ==========================================
# Install VS Code Extension
# ==========================================

install_vscode_extension() {

    local extension="$1"

    action "Installing $extension..."

    if [[ "$VERBOSE" == true ]]; then

    code --install-extension "$extension"

else

    code --install-extension "$extension" >/dev/null 2>&1

fi

if [[ $? -eq 0 ]]; then

    success "$extension installed successfully"
    return 0

fi

error "Failed to install $extension"
return 2

}

# ==========================================
# Install VS Code Extensions
# ==========================================

install_vscode_extensions() {

    if blueprint_exists &&
       [[ -z "$(blueprint_selected_items vscode-extensions)" ]]; then
        success "No VS Code extensions selected by Blueprint"
        return 0
    fi

    check_vscode_cli || return 1

    local config_file
    config_file="$(blueprint_generated_file vscode-extensions)"

    if [[ ! -f "$config_file" ]]; then

        error "Configuration file $config_file not found"
        return 2

    fi

    local installed_extensions
    if ! installed_extensions="$(code --list-extensions)"; then
        error "Failed to inspect installed VS Code extensions"
        return 2
    fi

    local missing_extensions=0

    while IFS= read -r extension || [[ -n "$extension" ]]; do

        [[ -z "$extension" ]] && continue
        [[ "$extension" =~ ^# ]] && continue
        blueprint_item_selected vscode-extensions "$extension" || continue

        if grep -Fxq "$extension" <<< "$installed_extensions"; then

            detail "$extension is already installed"
            continue

        fi

        ((missing_extensions++))

        if [[ $missing_extensions -eq 1 ]]; then

            action "Installing VS Code Extensions..."
            echo

        fi

        install_vscode_extension "$extension"

        if [[ $? -ne 0 ]]; then
            return 2
        fi

        MODULE_CHANGED=true

    done < "$config_file"

    if [[ $missing_extensions -eq 0 ]]; then

        success "All VS Code extensions are installed."
        return 0

    fi

    echo
    success "VS Code Extensions are ready"

}
