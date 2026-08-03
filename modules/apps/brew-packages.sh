#!/bin/bash

# ==========================================
# Homebrew Packages
# ==========================================

install_brew_packages() {

    local config_file="config/brew-packages.conf"

    if [[ ! -f "$config_file" ]]; then
        error "Configuration file $config_file not found"
        return 2
    fi

    info "Installing Homebrew Packages..."

    while IFS= read -r package || [[ -n "$package" ]]; do

        [[ -z "$package" ]] && continue
        [[ "$package" =~ ^# ]] && continue

        if brew list "$package" >/dev/null 2>&1; then
            info "$package is already installed"
        else
            info "Installing $package..."
            brew install "$package"
        fi

    done < "$config_file"

    success "Homebrew Packages are ready"

    return 0

}
