#!/bin/bash

# ==========================================
# Install App Store Application
# ==========================================

install_appstore_app() {

    local app_id="$1"
    local app_name="$2"

    info "Installing $app_name..."

    if MAS_NO_AUTO_INDEX=1 mas install "$app_id" 2>/dev/null; then

        success "$app_name installed successfully"
        return 0

    fi

    error "Failed to install $app_name"
    return 2

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

    MAS_INSTALLED_APPS="$(MAS_NO_AUTO_INDEX=1 mas list 2>/dev/null)"

    local missing_apps=0

    while IFS='|' read -r app_id app_name || [[ -n "$app_id" ]]; do

        [[ -z "$app_id" ]] && continue
        [[ "$app_id" =~ ^# ]] && continue

        if grep -Fq "$app_name" <<< "$MAS_INSTALLED_APPS"; then
            continue
        fi

        ((missing_apps++))

        if [[ $missing_apps -eq 1 ]]; then
            info "Installing App Store applications..."
            echo
        fi

        install_appstore_app "$app_id" "$app_name"

        if [[ $? -ne 0 ]]; then
            return 2
        fi

    done < "$config_file"

    if [[ $missing_apps -eq 0 ]]; then

        success "All App Store applications are installed."
        return 0

    fi

    echo
    success "App Store applications are ready"

}
