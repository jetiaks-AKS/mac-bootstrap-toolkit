# ==========================================
# Finder Discovery
# ==========================================

serialize_finder_settings() {

    local output_file="$1"

    : > "$output_file" || return 2

    macos_collect_preference "$output_file" NSGlobalDomain AppleShowAllExtensions bool || return 2
    macos_collect_preference "$output_file" com.apple.finder ShowPathbar bool || return 2
    macos_collect_preference "$output_file" com.apple.finder ShowStatusBar bool || return 2
    macos_collect_preference "$output_file" com.apple.finder FXPreferredViewStyle string || return 2
    macos_collect_preference "$output_file" com.apple.finder FXDefaultSearchScope string || return 2
    macos_collect_preference "$output_file" com.apple.finder _FXSortFoldersFirst bool || return 2
    macos_collect_preference "$output_file" com.apple.finder FXRemoveOldTrashItems bool || return 2

    return 0

}

export_finder_settings() {

    local output_file="config/generated/macos/finder.conf"

    action "Exporting Finder configuration..."

    if ! discovery_publish_file "$output_file" serialize_finder_settings; then
        error "Failed to export Finder configuration"
        return 2
    fi

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Finder configuration exported"

    return 0

}
