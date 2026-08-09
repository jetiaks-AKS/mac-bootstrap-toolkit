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

    apply_defaults_config "$FINDER_CONFIG"

    killall Finder >/dev/null 2>&1

    success "Finder configured successfully"

}
