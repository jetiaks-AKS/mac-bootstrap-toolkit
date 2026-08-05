#!/bin/bash

# ==========================================
# Trackpad Discovery
# ==========================================

export_trackpad_settings() {

    local output_dir="config/generated/macos"
    local output_file="$output_dir/trackpad.conf"

    mkdir -p "$output_dir"

    action "Exporting Trackpad configuration..."

    cat > "$output_file" <<EOF
TRACKPAD_CLICKING="$(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null)"
TRACKPAD_SCALING="$(defaults read NSGlobalDomain com.apple.trackpad.scaling 2>/dev/null)"
TRACKPAD_RIGHT_CLICK="$(defaults read com.apple.AppleMultitouchTrackpad TrackpadRightClick 2>/dev/null)"
EOF

    success "Trackpad configuration exported"

}
