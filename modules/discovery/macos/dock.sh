# ==========================================
# Dock Discovery
# ==========================================

export_dock_settings() {

    local output_dir="config/generated/macos"
    local output_file="$output_dir/dock.conf"

    mkdir -p "$output_dir"

    action "Exporting Dock configuration..."

    cat > "$output_file" <<EOF
DOCK_AUTOHIDE="$(defaults read com.apple.dock autohide 2>/dev/null)"
DOCK_SHOW_RECENTS="$(defaults read com.apple.dock show-recents 2>/dev/null)"
DOCK_TILESIZE="$(defaults read com.apple.dock tilesize 2>/dev/null)"
DOCK_MAGNIFICATION="$(defaults read com.apple.dock magnification 2>/dev/null)"
DOCK_LARGESIZE="$(defaults read com.apple.dock largesize 2>/dev/null)"
EOF

    success "Dock configuration exported"

}
