#!/bin/bash

# ==========================================
# Trackpad Settings
# ==========================================

TRACKPAD_CONFIG="${BLUEPRINT_GENERATED_DIR:-config/generated}/macos/trackpad.conf"

# ==========================================
# Check Trackpad
# ==========================================

check_trackpad() {

    check_defaults_config "$TRACKPAD_CONFIG" trackpad

}

# ==========================================
# Apply Trackpad Settings
# ==========================================

apply_trackpad_settings() {

    info "Configuring Trackpad..."

    if ! apply_defaults_config "$TRACKPAD_CONFIG" trackpad; then
        error "Failed to configure Trackpad"
        return 2
    fi

    if ! check_trackpad; then
        error "Failed to verify Trackpad preferences"
        return 2
    fi

    success "Trackpad preferences configured successfully"
    return 0

}
