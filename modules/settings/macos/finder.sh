#!/bin/bash

# ==========================================
# Finder Settings
# ==========================================

FINDER_CONFIG="config/generated/macos/finder.conf"

# ==========================================
# Check Finder
# ==========================================

check_finder() {

    check_defaults_config "$FINDER_CONFIG" finder

}

# ==========================================
# Apply Finder Settings
# ==========================================

apply_finder_settings() {

    info "Configuring Finder..."

    if ! apply_defaults_config "$FINDER_CONFIG" finder; then
        error "Failed to configure Finder"
        return 2
    fi

    if [[ "$DEFAULTS_CONFIG_CHANGED" == true ]] && ! killall Finder >/dev/null 2>&1; then
        error "Failed to restart Finder"
        return 2
    fi

    if ! check_finder; then
        error "Failed to verify Finder"
        return 2
    fi

    success "Finder configured successfully"
    return 0

}
