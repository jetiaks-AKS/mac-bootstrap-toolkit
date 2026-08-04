#!/bin/bash

# ==========================================
# Install Homebrew Packages
# ==========================================

install_brew_packages() {

    if ! command -v brew >/dev/null 2>&1; then

        error "Homebrew is not installed"
        return 2

    fi

    local config_file="config/brew-packages.conf"

    if [[ ! -f "$config_file" ]]; then

        error "Configuration file $config_file not found"
        return 2

    fi

    local missing_packages=0

    while IFS= read -r package || [[ -n "$package" ]]; do

        [[ -z "$package" ]] && continue
        [[ "$package" =~ ^# ]] && continue

        if brew list "$package" >/dev/null 2>&1; then

            detail "$package is already installed"
            continue

        fi

        ((missing_packages++))

        if [[ $missing_packages -eq 1 ]]; then
            action "Installing Homebrew Packages..."
            echo
        fi

        action "Installing $package..."

        if ! HOMEBREW_NO_ENV_HINTS=1 brew install "$package"; then

            error "Failed to install $package"
            return 2

        fi

        success "$package installed successfully"

    done < "$config_file"

    if [[ $missing_packages -eq 0 ]]; then

        success "All Homebrew packages are installed."
        return 0

    fi

    MODULE_CHANGED=true

    echo
    success "Homebrew Packages are ready"

}
