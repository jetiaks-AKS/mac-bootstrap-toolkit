#!/bin/bash

# ==========================================
# Screenshots Settings
# ==========================================

SCREENSHOTS_CONFIG="config/generated/macos/screenshots.conf"

# ==========================================
# Check Screenshots
# ==========================================

check_screenshots() {

    check_defaults_config "$SCREENSHOTS_CONFIG"

}

# ==========================================
# Apply Screenshot Settings
# ==========================================

apply_screenshots_settings() {

    info "Configuring Screenshots..."

    local screenshots_directory_created=false

    if ! validate_defaults_config "$SCREENSHOTS_CONFIG"; then
        error "Failed to validate Screenshots configuration"
        return 2
    fi

    if [[ ! -d "$HOME/Screenshots" ]]; then
        if ! mkdir -p "$HOME/Screenshots"; then
            error "Failed to create Screenshots directory"
            return 2
        fi
        screenshots_directory_created=true
    fi

    if ! apply_defaults_config "$SCREENSHOTS_CONFIG"; then
        error "Failed to configure Screenshots"
        [[ "$screenshots_directory_created" == true ]] && MODULE_CHANGED=true
        return 2
    fi

    [[ "$screenshots_directory_created" == true ]] && MODULE_CHANGED=true

    if ! killall SystemUIServer >/dev/null 2>&1; then
        error "Failed to restart SystemUIServer"
        return 2
    fi

    success "Screenshots configured successfully"
    return 0

}
