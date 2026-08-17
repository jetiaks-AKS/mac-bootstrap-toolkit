# ==========================================
# Dock Discovery
# ==========================================

serialize_dock_settings() {

    local output_file="$1"

    : > "$output_file" || return 2

    macos_collect_preference "$output_file" com.apple.dock autohide bool || return 2
    macos_collect_preference "$output_file" com.apple.dock show-recents bool || return 2
    macos_collect_preference "$output_file" com.apple.dock tilesize int || return 2
    macos_collect_preference "$output_file" com.apple.dock magnification bool || return 2
    macos_collect_preference "$output_file" com.apple.dock largesize int || return 2

    return 0

}

export_dock_settings() {

    local output_file="config/generated/macos/dock.conf"

    action "Exporting Dock configuration..."

    if ! discovery_publish_file "$output_file" serialize_dock_settings; then
        error "Failed to export Dock configuration"
        return 2
    fi

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Dock configuration exported"

    return 0

}
