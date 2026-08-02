#!/bin/bash

# ==========================================
# Проверка Trackpad
# ==========================================

check_trackpad() {

    info "Проверяю Trackpad..."

    local configured=true

    [[ "$(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read NSGlobalDomain com.apple.trackpad.scaling 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.AppleMultitouchTrackpad TrackpadRightClick 2>/dev/null)" == "1" ]] || configured=false

    if $configured; then
        success "Trackpad уже настроен"
    else
        warning "Trackpad требует настройки"
    fi

}

# ==========================================
# Настройка Trackpad
# ==========================================

apply_trackpad_settings() {

    info "Настраиваю Trackpad..."

    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write NSGlobalDomain com.apple.trackpad.scaling -int 1
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

    success "Trackpad настроен"

}
