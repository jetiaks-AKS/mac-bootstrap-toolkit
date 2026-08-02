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
# Проверка macOS
# ==========================================

check_macos_settings() {

    run_module "Finder" check_finder
    run_module "Dock" check_dock
    run_module "Keyboard" check_keyboard
    run_module "Trackpad" check_trackpad
    run_module "Screenshots" check_screenshots

}

# ==========================================
# Настройка macOS
# ==========================================

apply_macos_settings() {

    section "Finder"
    apply_finder_settings

    section "Dock"
    apply_dock_settings

    section "Keyboard"
    apply_keyboard_settings

    section "Trackpad"
    apply_trackpad_settings

    section "Screenshots"
    apply_screenshots_settings

}
