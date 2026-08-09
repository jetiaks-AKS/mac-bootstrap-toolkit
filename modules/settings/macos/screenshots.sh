#!/bin/bash

# ==========================================
# Screenshots Settings
# ==========================================

SCREENSHOTS_CONFIG="config/generated/macos/screenshots.conf"

# ==========================================
# Check Screenshots
# ==========================================

check_screenshots() {

    check_defaults_config "$SCREENSHOTS_CONFIG"

}

# ==========================================
# Apply Screenshot Settings
# ==========================================

apply_screenshots_settings() {

    info "Configuring Screenshots..."

    mkdir -p "$HOME/Screenshots"

    apply_defaults_config "$SCREENSHOTS_CONFIG"

    killall SystemUIServer >/dev/null 2>&1

    success "Screenshots configured successfully"

}
