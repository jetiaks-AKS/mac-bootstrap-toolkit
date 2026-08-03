#!/bin/bash

# ==========================================
# Check Keyboard
# ==========================================

check_keyboard() {

    info "Checking Keyboard..."

    local configured=true

    [[ "$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null)" == "5" ]] || configured=false
    [[ "$(defaults read NSGlobalDomain InitialKeyRepeat 2>/dev/null)" == "15" ]] || configured=false

    if $configured; then

    success "Keyboard is already configured"
    return 0

    fi

    warning "Keyboard requires configuration"
    return 1

}

# ==========================================
# Apply Keyboard Settings
# ==========================================

apply_keyboard_settings() {

    info "Configuring Keyboard..."

    defaults write NSGlobalDomain KeyRepeat -int 5
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    success "Keyboard configured successfully"

}
