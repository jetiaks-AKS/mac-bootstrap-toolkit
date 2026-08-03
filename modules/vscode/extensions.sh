#!/bin/bash

# ==========================================
# Check VS Code CLI
# ==========================================

is_code_installed() {

    command -v code >/dev/null 2>&1

}

# ==========================================
# Install VS Code Extension
# ==========================================

install_vscode_extension() {

    local extension="$1"

    if grep -Fxq "$extension" <<< "$VSCODE_EXTENSIONS"; then

        info "$extension is already installed"
        return 0

    fi

    info "Installing $extension..."

    if code --install-extension "$extension" >/dev/null 2>&1; then

        success "$extension installed successfully"

    else

        error "Failed to install $extension"

    fi

    VSCODE_EXTENSIONS="$(code --list-extensions)"

}

# ==========================================
# Install VS Code Extensions
# ==========================================

install_vscode_extensions() {

    local config_file="config/vscode-extensions.conf"
    local VSCODE_EXTENSIONS

    if [[ ! -f "$config_file" ]]; then

        error "Configuration file $config_file not found"
        return 2

    fi

    if ! is_code_installed; then

        warning "The 'code' command is not available"
        return 1

    fi

    info "Installing VS Code Extensions..."

    VSCODE_EXTENSIONS="$(code --list-extensions)"

    while IFS= read -r extension || [[ -n "$extension" ]]; do

        [[ -z "$extension" ]] && continue
        [[ "$extension" =~ ^# ]] && continue

        install_vscode_extension "$extension"

    done < "$config_file"

    success "VS Code Extensions are ready"

}
