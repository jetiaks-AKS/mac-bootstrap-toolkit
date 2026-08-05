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
SCREENSHOTS_LOCATION="$(defaults read com.apple.screencapture location 2>/dev/null)"
EOF

    success "Screenshots configuration exported"

}
