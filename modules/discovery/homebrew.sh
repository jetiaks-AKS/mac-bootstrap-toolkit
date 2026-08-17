#!/bin/bash

# ==========================================
# Homebrew Discovery
# ==========================================

export_brew_packages() {

    local output_dir="config/generated"
    local output_file="$output_dir/brew-packages.conf"

    mkdir -p "$output_dir"

    action "Exporting Homebrew Formulae..."

    local inventory
    if ! inventory="$(brew list --formula --installed-on-request)"; then
        error "Failed to inventory Homebrew Formulae"
        return 2
    fi

    > "$output_file"

    local package_count=0

    while IFS= read -r package; do

        [[ -z "$package" ]] && continue

        echo "$package" >> "$output_file"

        ((package_count++))

        detail "$package"

    done <<< "$inventory"

    success "$package_count Formulae exported"

}

# ==========================================

export_brew_casks() {

    local output_dir="config/generated"
    local output_file="$output_dir/brew-casks.conf"

    mkdir -p "$output_dir"

    action "Exporting Homebrew Casks..."

    local inventory
    if ! inventory="$(brew list --cask)"; then
        error "Failed to inventory Homebrew Casks"
        return 2
    fi

    > "$output_file"

    local cask_count=0

    while IFS= read -r cask; do

        [[ -z "$cask" ]] && continue

        echo "$cask" >> "$output_file"

        ((cask_count++))

        detail "$cask"

    done <<< "$inventory"

    success "$cask_count Casks exported"

}

# ==========================================

discover_homebrew() {

    if ! command -v brew >/dev/null 2>&1; then

        error "Homebrew is not installed"
        return 2

    fi

    export_brew_packages || return 2

    echo

    export_brew_casks || return 2

    echo

    success "Homebrew Discovery completed"

    return 0

}
