#!/bin/bash

# ==========================================
# macOS Settings
# ==========================================

source modules/settings/macos/defaults.sh
source modules/settings/macos/finder.sh
source modules/settings/macos/dock.sh
source modules/settings/macos/keyboard.sh
source modules/settings/macos/trackpad.sh
source modules/settings/macos/screenshots.sh

# ==========================================
# Check macOS Settings
# ==========================================

check_macos_settings() {

    if blueprint_category_enabled macos-finder; then
        check_finder >/dev/null 2>&1 || return 1
    fi

    if blueprint_category_enabled macos-dock; then
        check_dock >/dev/null 2>&1 || return 1
    fi

    if blueprint_category_enabled macos-keyboard; then
        check_keyboard >/dev/null 2>&1 || return 1
    fi

    if blueprint_category_enabled macos-trackpad; then
        check_trackpad >/dev/null 2>&1 || return 1
    fi

    if blueprint_category_enabled macos-screenshots; then
        check_screenshots >/dev/null 2>&1 || return 1
    fi

    return 0

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

    if blueprint_category_enabled macos-finder &&
       ! check_finder >/dev/null 2>&1; then
        apply_finder_settings
    fi

    if blueprint_category_enabled macos-dock &&
       ! check_dock >/dev/null 2>&1; then
        apply_dock_settings
    fi

    if blueprint_category_enabled macos-keyboard &&
       ! check_keyboard >/dev/null 2>&1; then
        apply_keyboard_settings
    fi

    if blueprint_category_enabled macos-trackpad &&
       ! check_trackpad >/dev/null 2>&1; then
        apply_trackpad_settings
    fi

    if blueprint_category_enabled macos-screenshots &&
       ! check_screenshots >/dev/null 2>&1; then
        apply_screenshots_settings
    fi

}
