#!/bin/bash

# ==========================================
# Dock Settings
# ==========================================

DOCK_CONFIG="config/generated/macos/dock.conf"

# ==========================================
# Check Dock
# ==========================================

check_dock() {

    check_defaults_config "$DOCK_CONFIG" dock

}

# ==========================================
# Apply Dock Settings
# ==========================================

apply_dock_settings() {

    info "Configuring Dock..."

    if ! apply_defaults_config "$DOCK_CONFIG" dock; then
        error "Failed to configure Dock"
        return 2
    fi

    if [[ "$DEFAULTS_CONFIG_CHANGED" == true ]] && ! killall Dock >/dev/null 2>&1; then
        error "Failed to restart Dock"
        return 2
    fi

    if ! check_dock; then
        error "Failed to verify Dock"
        return 2
    fi

    success "Dock configured successfully"
    return 0

}
