#!/bin/bash

# ==========================================
# Screenshots Discovery
# ==========================================

serialize_screenshots_settings() {

    local output_file="$1"

    : > "$output_file" || return 2

    macos_collect_preference "$output_file" com.apple.screencapture location string || return 2

    return 0

}

export_screenshots_settings() {

    local output_file="config/generated/macos/screenshots.conf"

    action "Exporting Screenshots configuration..."

    if ! discovery_publish_file "$output_file" serialize_screenshots_settings; then
        error "Failed to export Screenshots configuration"
        return 2
    fi

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Screenshots configuration exported"

    return 0

}
