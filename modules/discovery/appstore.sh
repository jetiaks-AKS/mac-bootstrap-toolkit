#!/bin/bash

# ==========================================
# App Store Discovery
# ==========================================

discover_appstore() {

    if ! command -v mas >/dev/null 2>&1; then

        warning "mas is not installed"
        return 1

    fi

    local output_dir="config/generated"
    local output_file="$output_dir/appstore.conf"

    mkdir -p "$output_dir"

    action "Exporting App Store applications..."

    MAS_NO_AUTO_INDEX=1 mas list > "$output_file"

    local app_count
    app_count=$(wc -l < "$output_file" | tr -d ' ')

    success "$app_count App Store application(s) exported"

}
