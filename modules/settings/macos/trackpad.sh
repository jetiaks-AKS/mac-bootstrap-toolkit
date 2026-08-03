#!/bin/bash

# ==========================================
# Check Trackpad
# ==========================================

check_trackpad() {

    info "Checking Trackpad..."

    local configured=true

    [[ "$(defaults read com.apple.AppleMultitouchTrackpad Clicking 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read NSGlobalDomain com.apple.trackpad.scaling 2>/dev/null)" == "1" ]] || configured=false
    [[ "$(defaults read com.apple.AppleMultitouchTrackpad TrackpadRightClick 2>/dev/null)" == "1" ]] || configured=false

    if $configured; then

    success "Trackpad is already configured"
    return 0

    fi

    warning "Trackpad requires configuration"
    return 1

}

# ==========================================
# Apply Trackpad Settings
# ==========================================

apply_trackpad_settings() {

    info "Configuring Trackpad..."

    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write NSGlobalDomain com.apple.trackpad.scaling -int 1
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

    success "Trackpad configured successfully"

}
