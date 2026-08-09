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

    MAS_NO_AUTO_INDEX=1 mas list | awk '{
        app_id=$1
        $1=""
        sub(/^[[:space:]]+/, "")
        sub(/[[:space:]]+\([^()]+\)$/, "")
        print app_id "|" $0
    }' > "$output_file"

    local app_count
    app_count=$(wc -l < "$output_file" | tr -d ' ')

    if [[ "$VERBOSE" == true ]]; then

        while IFS="|" read -r app_id app_name; do

            [[ -z "$app_id" ]] && continue

            detail "$app_id  $app_name"

        done < "$output_file"

    fi

    success "$app_count App Store application(s) exported"

}
