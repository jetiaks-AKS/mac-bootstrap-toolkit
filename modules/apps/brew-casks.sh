#!/bin/bash

# ==========================================
# Install Homebrew Cask
# ==========================================

install_brew_cask() {

    local cask="$1"

    info "Installing $cask..."

    if HOMEBREW_NO_ENV_HINTS=1 brew install --cask "$cask"; then

        success "$cask installed successfully"
        return 0

    fi

    error "Failed to install $cask"
    return 2

}

# ==========================================
# Install Homebrew Casks
# ==========================================

install_brew_casks() {

    if ! command -v brew >/dev/null 2>&1; then

        error "Homebrew is not installed"
        return 2

    fi

    local config_file="config/brew-casks.conf"

    if [[ ! -f "$config_file" ]]; then

        error "Configuration file $config_file not found"
        return 2

    fi

    local missing_casks=0

    while IFS= read -r cask || [[ -n "$cask" ]]; do

        [[ -z "$cask" ]] && continue
        [[ "$cask" =~ ^# ]] && continue

        if brew list --cask "$cask" >/dev/null 2>&1; then

            detail "$cask is already installed"
            continue

        fi

        ((missing_casks++))

        if [[ $missing_casks -eq 1 ]]; then
            info "Installing Homebrew Casks..."
            echo
        fi

        install_brew_cask "$cask"

        if [[ $? -ne 0 ]]; then
            return 2
        fi

    done < "$config_file"

    if [[ $missing_casks -eq 0 ]]; then

        success "All Homebrew casks are installed."
        return 0

    fi

    echo
    success "Homebrew Casks are ready"

}
