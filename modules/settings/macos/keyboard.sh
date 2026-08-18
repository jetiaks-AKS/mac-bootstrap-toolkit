#!/bin/bash

# ==========================================
# Keyboard Settings
# ==========================================

KEYBOARD_CONFIG="config/generated/macos/keyboard.conf"

# ==========================================
# Check Keyboard
# ==========================================

check_keyboard() {

    check_defaults_config "$KEYBOARD_CONFIG"

}

# ==========================================
# Apply Keyboard Settings
# ==========================================

apply_keyboard_settings() {

    info "Configuring Keyboard..."

    if ! apply_defaults_config "$KEYBOARD_CONFIG"; then
        error "Failed to configure Keyboard"
        return 2
    fi

    success "Keyboard configured successfully"
    return 0

}
