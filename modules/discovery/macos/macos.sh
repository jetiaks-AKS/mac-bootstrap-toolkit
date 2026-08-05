#!/bin/bash

# ==========================================
# macOS Discovery
# ==========================================

source modules/discovery/macos/finder.sh
source modules/discovery/macos/dock.sh
source modules/discovery/macos/keyboard.sh
source modules/discovery/macos/trackpad.sh
source modules/discovery/macos/screenshots.sh
source modules/discovery/macos/dock.sh

discover_macos() {

    export_finder_settings

    echo

    export_dock_settings

    echo

    export_keyboard_settings

    echo

    export_trackpad_settings

    echo

    export_screenshots_settings

    echo

    success "macOS Discovery completed"

}
