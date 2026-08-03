#!/bin/bash

# ==========================================
# Check Screenshots
# ==========================================

check_screenshots() {

    info "Checking Screenshots..."

    local configured=true
    local location

    location="$(defaults read com.apple.screencapture location 2>/dev/null)"

    [[ "$location" == "~/Screenshots" || "$location" == "$HOME/Screenshots" ]] || configured=false

    if $configured; then

    success "Screenshots are already configured"
    return 0

    fi

    warning "Screenshots require configuration"
    return 1

}

# ==========================================
# Apply Screenshot Settings
# ==========================================

apply_screenshots_settings() {

    info "Configuring Screenshots..."

    mkdir -p "$HOME/Screenshots"

    defaults write com.apple.screencapture location "$HOME/Screenshots"

    killall SystemUIServer >/dev/null 2>&1

    success "Screenshots configured successfully"

}
