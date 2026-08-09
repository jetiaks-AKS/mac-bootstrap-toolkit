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
com.apple.AppleMultitouchTrackpad|Clicking|bool|$(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null)
NSGlobalDomain|com.apple.trackpad.scaling|int|$(defaults read NSGlobalDomain com.apple.trackpad.scaling 2>/dev/null)
com.apple.AppleMultitouchTrackpad|TrackpadRightClick|bool|$(defaults read com.apple.AppleMultitouchTrackpad TrackpadRightClick 2>/dev/null)
EOF

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Trackpad configuration exported"

}
