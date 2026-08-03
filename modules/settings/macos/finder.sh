#!/bin/bash

# ==========================================
# Check Finder
# ==========================================

check_finder() {

    info "Checking Finder..."

    local configured=true

    [[ "$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.finder ShowPathbar 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.finder ShowStatusBar 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.finder FXPreferredViewStyle 2>/dev/null)" == "Nlsv" ]] || configured=false
    [[ "$(defaults read com.apple.finder FXDefaultSearchScope 2>/dev/null)" == "SCcf" ]] || configured=false

    [[ "$(defaults read com.apple.finder _FXSortFoldersFirst 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.finder FXRemoveOldTrashItems 2>/dev/null)" == "1" ]] || configured=false

    if $configured; then
        success "Finder is already configured"
    else
        warning "Finder requires configuration"
    fi

}

# ==========================================
# Apply Finder Settings
# ==========================================

apply_finder_settings() {

    info "Configuring Finder..."

    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true

    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.finder FXRemoveOldTrashItems -bool true

    killall Finder >/dev/null 2>&1

    success "Finder configured successfully"

}
