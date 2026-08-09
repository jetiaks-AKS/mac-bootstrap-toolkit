#!/bin/bash

# ==========================================
# Install Homebrew Cask
# ==========================================

# ==========================================
# Check Homebrew Cask
# ==========================================

is_cask_installed() {

    local cask="$1"
    local output
    local app_path

    output="$(brew list --cask "$cask" 2>&1)"
    app_path="$(
    brew info --json=v2 --cask "$cask" |
    jq -r '.casks[0].artifacts[]? | select(.target != null) | .target' |
    head -n1
)"

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    if [[ -n "$app_path" && ! -e "$app_path" ]]; then
    return 1
    fi

    return 0

}

install_brew_cask() {

    local cask="$1"

    action "Installing $cask..."

    local install_command="install"

if ! is_cask_installed "$cask"; then

    local app_path

    app_path="$(
        brew info --json=v2 --cask "$cask" |
        jq -r '.casks[0].artifacts[]? | select(.target != null) | .target' |
        head -n1
    )"

    if [[ -n "$app_path" && ! -e "$app_path" ]]; then

        install_command="reinstall"

    fi

fi

    if [[ "$VERBOSE" == true ]]; then

    HOMEBREW_NO_ENV_HINTS=1 brew "$install_command" --cask "$cask"

else

    HOMEBREW_NO_ENV_HINTS=1 brew "$install_command" --cask "$cask" >/dev/null 2>&1

fi

if is_cask_installed "$cask"; then

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

    local config_file="config/generated/brew-casks.conf"

    if [[ ! -f "$config_file" ]]; then

        error "Configuration file $config_file not found"
        return 2

    fi

    local missing_casks=0

    while IFS= read -r cask || [[ -n "$cask" ]]; do

        [[ -z "$cask" ]] && continue
        [[ "$cask" =~ ^# ]] && continue

        if is_cask_installed "$cask"; then

            detail "$cask is already installed"
            continue

        fi

        ((missing_casks++))

        MODULE_CHANGED=true

        if [[ $missing_casks -eq 1 ]]; then
            action "Installing Homebrew Casks..."
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
