#!/bin/bash

# ==========================================
# Trackpad Settings
# ==========================================

TRACKPAD_CONFIG="config/generated/macos/trackpad.conf"

# ==========================================
# Check Trackpad
# ==========================================

check_trackpad() {

    check_defaults_config "$TRACKPAD_CONFIG"

}

# ==========================================
# Apply Trackpad Settings
# ==========================================

apply_trackpad_settings() {

    info "Configuring Trackpad..."

    apply_defaults_config "$TRACKPAD_CONFIG"

    success "Trackpad configured successfully"

}
