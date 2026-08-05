#!/bin/bash

# ==========================================
# Homebrew Discovery
# ==========================================

discover_homebrew() {

    if ! command -v brew >/dev/null 2>&1; then

        error "Homebrew is not installed"
        return 2

    fi

    local output_dir="config/generated"
    local output_file="$output_dir/brew-packages.conf"

    mkdir -p "$output_dir"

    action "Analyzing installed Homebrew packages..."

    > "$output_file"

    local package_count=0

    while IFS= read -r package; do

        [[ -z "$package" ]] && continue

        echo "$package" >> "$output_file"

        ((package_count++))

        detail "$package"

    done < <(brew list --formula)

    echo

    success "$package_count Homebrew package(s) exported"

    detail "Configuration saved to:"
    detail "$output_file"

    return 0

}
