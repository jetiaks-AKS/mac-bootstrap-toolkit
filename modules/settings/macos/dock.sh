#!/bin/bash

# ==========================================
# Dock Settings
# ==========================================

DOCK_CONFIG="config/generated/macos/dock.conf"

# ==========================================
# Check Dock
# ==========================================

check_dock() {

    check_defaults_config "$DOCK_CONFIG"

}

# ==========================================
# Apply Dock Settings
# ==========================================

apply_dock_settings() {

    info "Configuring Dock..."

    if ! apply_defaults_config "$DOCK_CONFIG"; then
        error "Failed to configure Dock"
        return 2
    fi

    if ! killall Dock >/dev/null 2>&1; then
        error "Failed to restart Dock"
        return 2
    fi

    success "Dock configured successfully"
    return 0

}
