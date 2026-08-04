#!/bin/bash

# ==========================================
# macOS Settings
# ==========================================

source modules/settings/macos/finder.sh
source modules/settings/macos/dock.sh
source modules/settings/macos/keyboard.sh
source modules/settings/macos/trackpad.sh
source modules/settings/macos/screenshots.sh

# ==========================================
# Check macOS Settings
# ==========================================

check_macos_settings() {

    local configured=true

    check_finder >/dev/null 2>&1 || configured=false
    check_dock >/dev/null 2>&1 || configured=false
    check_keyboard >/dev/null 2>&1 || configured=false
    check_trackpad >/dev/null 2>&1 || configured=false
    check_screenshots >/dev/null 2>&1 || configured=false

    if $configured; then

        success "macOS Settings are already configured"
        return 0

    fi

    warning "macOS Settings require configuration"
    return 1

}

# ==========================================
# Apply macOS Settings
# ==========================================

apply_macos_settings() {

    run_configuration \
        "macOS Settings" \
        check_macos_settings \
        apply_macos_components

}

# ==========================================
# Apply macOS Components
# ==========================================

apply_macos_components() {

    if ! check_finder >/dev/null 2>&1; then
        apply_finder_settings
    fi

    if ! check_dock >/dev/null 2>&1; then
        apply_dock_settings
    fi

    if ! check_keyboard >/dev/null 2>&1; then
        apply_keyboard_settings
    fi

    if ! check_trackpad >/dev/null 2>&1; then
        apply_trackpad_settings
    fi

    if ! check_screenshots >/dev/null 2>&1; then
        apply_screenshots_settings
    fi

}
