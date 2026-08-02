#!/bin/bash

# ==========================================
# Проверка Dock
# ==========================================

check_dock() {

    info "Проверяю Dock..."

    local configured=true

    [[ "$(defaults read com.apple.dock autohide 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.dock tilesize 2>/dev/null)" == "59" ]] || configured=false

    if $configured; then
        success "Dock уже настроен"
    else
        warning "Dock требует настройки"
    fi

}

# ==========================================
# Настройка Dock
# ==========================================

apply_dock_settings() {

    info "Настраиваю Dock..."

    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock tilesize -int 59

    killall Dock >/dev/null 2>&1

    success "Dock настроен"

}
