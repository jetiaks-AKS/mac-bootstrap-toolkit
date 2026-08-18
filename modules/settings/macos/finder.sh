#!/bin/bash

# ==========================================
# Finder Settings
# ==========================================

FINDER_CONFIG="config/generated/macos/finder.conf"

# ==========================================
# Check Finder
# ==========================================

check_finder() {

    check_defaults_config "$FINDER_CONFIG"

}

# ==========================================
# Apply Finder Settings
# ==========================================

apply_finder_settings() {

    info "Configuring Finder..."

    if ! apply_defaults_config "$FINDER_CONFIG"; then
        error "Failed to configure Finder"
        return 2
    fi

    if ! killall Finder >/dev/null 2>&1; then
        error "Failed to restart Finder"
        return 2
    fi

    success "Finder configured successfully"
    return 0

}
