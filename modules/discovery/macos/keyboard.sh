#!/bin/bash

# ==========================================
# Keyboard Discovery
# ==========================================

export_keyboard_settings() {

    local output_dir="config/generated/macos"
    local output_file="$output_dir/keyboard.conf"

    mkdir -p "$output_dir"

    action "Exporting Keyboard configuration..."

    cat > "$output_file" <<EOF
KEYBOARD_KEY_REPEAT="$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null)"
KEYBOARD_INITIAL_KEY_REPEAT="$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null)"
EOF

    success "Keyboard configuration exported"

}
