# ==========================================
# Finder Discovery
# ==========================================

export_finder_settings() {

    local output_dir="config/generated/macos"
    local output_file="$output_dir/finder.conf"

    mkdir -p "$output_dir"

    action "Exporting Finder configuration..."

    cat > "$output_file" <<EOF
NSGlobalDomain|AppleShowAllExtensions|bool|$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)
com.apple.finder|ShowPathbar|bool|$(defaults read com.apple.finder ShowPathbar 2>/dev/null)
com.apple.finder|ShowStatusBar|bool|$(defaults read com.apple.finder ShowStatusBar 2>/dev/null)
com.apple.finder|FXPreferredViewStyle|string|$(defaults read com.apple.finder FXPreferredViewStyle 2>/dev/null)
com.apple.finder|FXDefaultSearchScope|string|$(defaults read com.apple.finder FXDefaultSearchScope 2>/dev/null)
com.apple.finder|_FXSortFoldersFirst|bool|$(defaults read com.apple.finder _FXSortFoldersFirst 2>/dev/null)
com.apple.finder|FXRemoveOldTrashItems|bool|$(defaults read com.apple.finder FXRemoveOldTrashItems 2>/dev/null)
EOF

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Finder configuration exported"

}
