# ==========================================
# Finder Discovery
# ==========================================

export_finder_settings() {

    local output_dir="config/generated/macos"
    local output_file="$output_dir/finder.conf"

    mkdir -p "$output_dir"

    action "Exporting Finder configuration..."

    cat > "$output_file" <<EOF
FINDER_SHOW_EXTENSIONS="$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)"
FINDER_SHOW_PATHBAR="$(defaults read com.apple.finder ShowPathbar 2>/dev/null)"
FINDER_SHOW_STATUSBAR="$(defaults read com.apple.finder ShowStatusBar 2>/dev/null)"
FINDER_VIEW_STYLE="$(defaults read com.apple.finder FXPreferredViewStyle 2>/dev/null)"
FINDER_SEARCH_SCOPE="$(defaults read com.apple.finder FXDefaultSearchScope 2>/dev/null)"
FINDER_SORT_FOLDERS_FIRST="$(defaults read com.apple.finder _FXSortFoldersFirst 2>/dev/null)"
FINDER_AUTO_REMOVE_TRASH="$(defaults read com.apple.finder FXRemoveOldTrashItems 2>/dev/null)"
EOF

    success "Finder configuration exported"

}
