#!/bin/bash

# ==========================================
# Проверка Keyboard
# ==========================================

check_keyboard() {

    info "Проверяю Keyboard..."

    local configured=true

    [[ "$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null)" == "5" ]] || configured=false
    [[ "$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null)" == "15" ]] || configured=false

    if $configured; then
        success "Keyboard уже настроена"
    else
        warning "Keyboard требует настройки"
    fi

}

# ==========================================
# Настройка Keyboard
# ==========================================

apply_keyboard_settings() {

    info "Настраиваю Keyboard..."

    defaults write NSGlobalDomain KeyRepeat -int 5
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    success "Keyboard настроена"

}
