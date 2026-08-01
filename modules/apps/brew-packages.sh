#!/bin/bash

# ==========================================
# Установка Homebrew Packages
# ==========================================

install_brew_packages() {

    local config_file="config/brew-packages.conf"

    if [[ ! -f "$config_file" ]]; then
        error "Файл $config_file не найден"
        return 2
    fi

    info "Устанавливаю Homebrew Packages..."

    while IFS= read -r package || [[ -n "$package" ]]; do

        [[ -z "$package" ]] && continue
        [[ "$package" =~ ^# ]] && continue

        if brew list "$package" >/dev/null 2>&1; then
            info "$package уже установлен"
        else
            info "Устанавливаю $package..."
            brew install "$package"
        fi

    done < "$config_file"

    success "Homebrew Packages готовы"

    return 0

}