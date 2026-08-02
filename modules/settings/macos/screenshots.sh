#!/bin/bash

# ==========================================
# Проверка Screenshots
# ==========================================

check_screenshots() {

    info "Проверяю Screenshots..."

    local configured=true
    local location

    location="$(defaults read com.apple.screencapture location 2>/dev/null)"

    [[ "$location" == "~/Screenshots" || "$location" == "$HOME/Screenshots" ]] || configured=false

    if $configured; then
        success "Screenshots уже настроены"
    else
        warning "Screenshots требуют настройки"
    fi

}

# ==========================================
# Настройка Screenshots
# ==========================================

apply_screenshots_settings() {

    info "Настраиваю Screenshots..."

    mkdir -p "$HOME/Screenshots"

    defaults write com.apple.screencapture location "$HOME/Screenshots"

    killall SystemUIServer >/dev/null 2>&1

    success "Screenshots настроены"

}
