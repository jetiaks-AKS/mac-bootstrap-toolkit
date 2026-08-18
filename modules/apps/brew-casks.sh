#!/bin/bash

# ==========================================
# Install Homebrew Cask
# ==========================================

# ==========================================
# Check Homebrew Cask
# ==========================================

CASK_REINSTALL_REQUIRED=false

is_cask_installed() {

    local cask="$1"
    local installed_casks
    local metadata
    local app_paths
    local app_path

    CASK_REINSTALL_REQUIRED=false

    if ! installed_casks="$(brew list --cask)"; then
        return 2
    fi

    if ! grep -Fxq "$cask" <<< "$installed_casks"; then
        return 1
    fi

    if ! metadata="$(brew info --json=v2 --cask "$cask")"; then
        return 2
    fi

    if ! app_paths="$(jq -r \
        '.casks[0].artifacts[]? | select(.target != null) | .target' \
        <<< "$metadata")"; then
        return 2
    fi

    IFS= read -r app_path <<< "$app_paths"

    if [[ -n "$app_path" && ! -e "$app_path" ]]; then
        CASK_REINSTALL_REQUIRED=true
        return 1
    fi

    return 0

}

install_brew_cask() {

    local cask="$1"
    local install_command="${2:-}"

    action "Installing $cask..."

    if [[ -z "$install_command" ]]; then
        is_cask_installed "$cask"
        local inspection_result=$?

        if [[ $inspection_result -eq 2 ]]; then
            error "Failed to inspect Homebrew cask: $cask"
            return 2
        fi

        install_command="install"
        if [[ "${CASK_REINSTALL_REQUIRED:-false}" == true ]]; then
            install_command="reinstall"
        fi
    fi

    if [[ "$VERBOSE" == true ]]; then

        HOMEBREW_NO_ENV_HINTS=1 brew "$install_command" --cask "$cask"

    else

        HOMEBREW_NO_ENV_HINTS=1 brew "$install_command" --cask "$cask" >/dev/null 2>&1

    fi

    local install_result=$?

    if [[ $install_result -ne 0 ]]; then
        error "Failed to install $cask"
        return 2
    fi

is_cask_installed "$cask"
local verification_result=$?

if [[ $verification_result -eq 0 ]]; then

    success "$cask installed successfully"
    return 0

fi

if [[ $verification_result -eq 2 ]]; then
    error "Failed to verify Homebrew cask: $cask"
    return 2
fi

error "Failed to install $cask"
return 2

}

# ==========================================
# Install Homebrew Casks
# ==========================================

install_brew_casks() {

    if blueprint_exists &&
       [[ -z "$(blueprint_selected_items homebrew-casks)" ]]; then
        success "No Homebrew casks selected by Blueprint"
        return 0
    fi

    if ! command -v brew >/dev/null 2>&1; then

        error "Homebrew is not installed"
        return 2

    fi

    local config_file
    config_file="$(blueprint_generated_file homebrew-casks)"

    if [[ ! -f "$config_file" ]]; then

        error "Configuration file $config_file not found"
        return 2

    fi

    local missing_casks=0

    while IFS= read -r cask || [[ -n "$cask" ]]; do

        [[ -z "$cask" ]] && continue
        [[ "$cask" =~ ^# ]] && continue
        blueprint_item_selected homebrew-casks "$cask" || continue

        is_cask_installed "$cask"
        local inspection_result=$?

        if [[ $inspection_result -eq 0 ]]; then

            detail "$cask is already installed"
            continue

        fi

        if [[ $inspection_result -eq 2 ]]; then
            error "Failed to inspect Homebrew cask: $cask"
            return 2
        fi

        ((missing_casks++))

        if [[ $missing_casks -eq 1 ]]; then
            action "Installing Homebrew Casks..."
            echo
        fi

        local install_command="install"
        if [[ "${CASK_REINSTALL_REQUIRED:-false}" == true ]]; then
            install_command="reinstall"
        fi

        install_brew_cask "$cask" "$install_command"

        if [[ $? -ne 0 ]]; then
            return 2
        fi

        MODULE_CHANGED=true

    done < "$config_file"

    if [[ $missing_casks -eq 0 ]]; then

        success "All Homebrew casks are installed."
        return 0

    fi

    echo
    success "Homebrew Casks are ready"

}
