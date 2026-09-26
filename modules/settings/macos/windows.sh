#!/bin/bash

# ==========================================
# Window Management Settings
# ==========================================

WINDOWS_CONFIG="${BLUEPRINT_GENERATED_DIR:-config/generated}/macos/windows.conf"

check_windows() {
    check_defaults_config "$WINDOWS_CONFIG" windows
}

apply_windows_settings() {
    info "Configuring Window Management..."

    if ! apply_defaults_config "$WINDOWS_CONFIG" windows; then
        error "Failed to configure Window Management"
        return 2
    fi

    if ! check_windows; then
        error "Failed to verify Window Management"
        return 2
    fi

    success "Window Management configured successfully"
    return 0
}
