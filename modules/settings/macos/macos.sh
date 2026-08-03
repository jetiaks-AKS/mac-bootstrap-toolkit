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

    run_module "Finder" check_finder
    run_module "Dock" check_dock
    run_module "Keyboard" check_keyboard
    run_module "Trackpad" check_trackpad
    run_module "Screenshots" check_screenshots

}

# ==========================================
# Apply macOS Settings
# ==========================================

apply_macos_settings() {

    run_configuration \
        "Finder" \
        check_finder \
        apply_finder_settings

    run_configuration \
        "Dock" \
        check_dock \
        apply_dock_settings

    run_configuration \
        "Keyboard" \
        check_keyboard \
        apply_keyboard_settings

    run_configuration \
        "Trackpad" \
        check_trackpad \
        apply_trackpad_settings

    run_configuration \
        "Screenshots" \
        check_screenshots \
        apply_screenshots_settings

}
