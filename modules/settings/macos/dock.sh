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

    apply_defaults_config "$DOCK_CONFIG"

    killall Dock >/dev/null 2>&1

    success "Dock configured successfully"

}
