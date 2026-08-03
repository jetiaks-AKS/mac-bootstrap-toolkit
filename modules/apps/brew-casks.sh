#!/bin/bash

# ==========================================
# Homebrew Casks
# ==========================================

install_brew_casks() {

    local config_file="config/brew-casks.conf"

    if [[ ! -f "$config_file" ]]; then
        error "Configuration file $config_file not found"
        return 2
    fi

    info "Installing Homebrew Casks..."

    while IFS= read -r cask || [[ -n "$cask" ]]; do

        [[ -z "$cask" ]] && continue
        [[ "$cask" =~ ^# ]] && continue

        app_name="$cask"

    if brew list --cask "$cask" >/dev/null 2>&1; then

    info "$cask is already installed"

else

    info "Installing $cask..."
    brew install --cask --adopt "$cask"

fi
    done < "$config_file"

    success "Homebrew Casks are ready"

    return 0

}
