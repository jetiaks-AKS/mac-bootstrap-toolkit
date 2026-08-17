#!/bin/bash

# ==========================================
# Trackpad Discovery
# ==========================================

serialize_trackpad_settings() {

    local output_file="$1"

    : > "$output_file" || return 2

    macos_collect_preference "$output_file" com.apple.AppleMultitouchTrackpad Clicking bool || return 2
    macos_collect_preference "$output_file" NSGlobalDomain com.apple.trackpad.scaling int || return 2
    macos_collect_preference "$output_file" com.apple.AppleMultitouchTrackpad TrackpadRightClick bool || return 2

    return 0

}

export_trackpad_settings() {

    local output_file="config/generated/macos/trackpad.conf"

    action "Exporting Trackpad configuration..."

    if ! discovery_publish_file "$output_file" serialize_trackpad_settings; then
        error "Failed to export Trackpad configuration"
        return 2
    fi

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Trackpad configuration exported"

    return 0

}
