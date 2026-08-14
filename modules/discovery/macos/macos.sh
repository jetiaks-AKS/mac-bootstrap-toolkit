#!/bin/bash

# ==========================================
# macOS Discovery
# ==========================================

source modules/discovery/macos/finder.sh
source modules/discovery/macos/dock.sh
source modules/discovery/macos/keyboard.sh
source modules/discovery/macos/trackpad.sh
source modules/discovery/macos/screenshots.sh


discover_macos() {

    local discovery_result=0
    local exporter_result

    export_finder_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_dock_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_keyboard_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_trackpad_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_screenshots_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    if [[ $discovery_result -eq 0 ]]; then
        success "macOS Discovery completed"
    elif [[ $discovery_result -eq 1 ]]; then
        warning "macOS Discovery completed with warnings"
    else
        error "macOS Discovery completed with errors"
    fi

    return "$discovery_result"

}
