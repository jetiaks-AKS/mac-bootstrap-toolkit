#!/bin/bash

# ==========================================
# Screenshots Discovery
# ==========================================

export_screenshots_settings() {

    local output_dir="config/generated/macos"
    local output_file="$output_dir/screenshots.conf"

    mkdir -p "$output_dir"

    action "Exporting Screenshots configuration..."

    cat > "$output_file" <<EOF
com.apple.screencapture|location|string|$(defaults read com.apple.screencapture location 2>/dev/null)
EOF

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Screenshots configuration exported"

}
