#!/bin/bash

# ==========================================
# Install App Store Application
# ==========================================

install_appstore_app() {

    local app_id="$1"
    local app_name="$2"

    if grep -Fq "$app_name" <<< "$MAS_INSTALLED_APPS"; then

        info "$app_name is already installed"
        return 0

    fi

    info "Installing $app_name..."

    if mas install "$app_id"; then
        success "$app_name installed successfully"

    else
        error "Failed to install $app_name"

    fi


}

# ==========================================
# Install App Store Applications
# ==========================================

install_appstore_apps() {

    if ! command -v mas >/dev/null 2>&1; then

        warning "mas is not installed"
        return 1

    fi

    local config_file="config/appstore.conf"

    if [[ ! -f "$config_file" ]]; then
        error "Configuration file $config_file not found"
        return 2
    fi

    info "Checking installed App Store applications..."

    MAS_INSTALLED_APPS="$(mas list)"

    info "Installing App Store applications..."

    while IFS='|' read -r app_id app_name || [[ -n "$app_id" ]]; do

        [[ -z "$app_id" ]] && continue
        [[ "$app_id" =~ ^# ]] && continue

        install_appstore_app "$app_id" "$app_name"

    done < "$config_file"

    success "App Store applications are ready"

}
