#!/bin/bash

# ==========================================
# Check Dock
# ==========================================

check_dock() {

    local configured=true

    [[ "$(defaults read com.apple.dock autohide 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.dock tilesize 2>/dev/null)" == "59" ]] || configured=false

    [[ "$(defaults read com.apple.dock mineffect 2>/dev/null)" == "scale" ]] || configured=false
    [[ "$(defaults read com.apple.dock minimize-to-application 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.dock show-recents 2>/dev/null)" == "0" ]] || configured=false

    if $configured; then

    success "Dock is already configured"
    return 0

    fi

    warning "Dock requires configuration"
    return 1

}

# ==========================================
# Apply Dock Settings
# ==========================================

apply_dock_settings() {

    info "Configuring Dock..."

    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock tilesize -int 59

    defaults write com.apple.dock mineffect -string "scale"
    defaults write com.apple.dock minimize-to-application -bool true
    defaults write com.apple.dock show-recents -bool false

    killall Dock >/dev/null 2>&1

    success "Dock configured successfully"

}
