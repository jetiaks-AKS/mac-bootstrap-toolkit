#!/bin/bash

# ==========================================
# Проверка Finder
# ==========================================

check_finder() {

    info "Проверяю Finder..."

    local configured=true

    [[ "$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.finder ShowPathbar 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.finder ShowStatusBar 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.finder FXPreferredViewStyle 2>/dev/null)" == "Nlsv" ]] || configured=false
    [[ "$(defaults read com.apple.finder FXDefaultSearchScope 2>/dev/null)" == "SCcf" ]] || configured=false

    if $configured; then
        success "Finder уже настроен"
    else
        warning "Finder требует настройки"
    fi

}

# ==========================================
# Настройка Finder
# ==========================================

apply_finder_settings() {

    info "Настраиваю Finder..."

    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    killall Finder >/dev/null 2>&1

    success "Finder настроен"

}
