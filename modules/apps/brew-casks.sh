#!/bin/bash

# ==========================================
# Установка Homebrew Casks
# ==========================================

install_brew_casks() {

    local config_file="config/brew-casks.conf"

    if [[ ! -f "$config_file" ]]; then
        error "Файл $config_file не найден"
        return 2
    fi

    info "Устанавливаю Homebrew Casks..."

    while IFS= read -r cask || [[ -n "$cask" ]]; do

        [[ -z "$cask" ]] && continue
        [[ "$cask" =~ ^# ]] && continue

        app_name="$cask"

    if brew list --cask "$cask" >/dev/null 2>&1; then

    info "$cask уже установлен"

else

    info "Устанавливаю $cask..."
    brew install --cask --adopt "$cask"

fi
    done < "$config_file"

    success "Homebrew Casks готовы"

    return 0

}