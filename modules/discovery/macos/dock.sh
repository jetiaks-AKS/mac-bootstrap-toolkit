# ==========================================
# Dock Discovery
# ==========================================

export_dock_settings() {

    local output_dir="config/generated/macos"
    local output_file="$output_dir/dock.conf"

    mkdir -p "$output_dir"

    action "Exporting Dock configuration..."

    cat > "$output_file" <<EOF
com.apple.dock|autohide|bool|$(defaults read com.apple.dock autohide 2>/dev/null)
com.apple.dock|show-recents|bool|$(defaults read com.apple.dock show-recents 2>/dev/null)
com.apple.dock|tilesize|int|$(defaults read com.apple.dock tilesize 2>/dev/null)
com.apple.dock|magnification|bool|$(defaults read com.apple.dock magnification 2>/dev/null)
com.apple.dock|largesize|int|$(defaults read com.apple.dock largesize 2>/dev/null)
EOF

    success "Dock configuration exported"

}
