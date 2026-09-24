#!/bin/bash

# ==========================================
# Keyboard Discovery
# ==========================================

serialize_keyboard_settings() {

    local output_file="$1"

    : > "$output_file" || return 2

    macos_collect_preference "$output_file" NSGlobalDomain KeyRepeat int || return 2
    macos_collect_preference "$output_file" NSGlobalDomain InitialKeyRepeat int || return 2
    macos_collect_preference "$output_file" NSGlobalDomain ApplePressAndHoldEnabled bool || return 2
    macos_collect_preference "$output_file" NSGlobalDomain AppleKeyboardUIMode int || return 2
    macos_collect_preference "$output_file" NSGlobalDomain NSAutomaticCapitalizationEnabled bool || return 2
    macos_collect_preference "$output_file" NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool || return 2
    macos_collect_preference "$output_file" NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool || return 2
    macos_collect_preference "$output_file" NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool || return 2
    macos_collect_preference "$output_file" NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool || return 2

    return 0

}

export_keyboard_settings() {

    local output_file="config/generated/macos/keyboard.conf"

    action "Exporting Keyboard configuration..."

    if ! discovery_publish_file "$output_file" macos_serialize_candidate keyboard serialize_keyboard_settings; then
        error "Failed to export Keyboard configuration"
        return 2
    fi

if [[ "$VERBOSE" == true ]]; then
    detail "Configuration saved to: $output_file"
fi
    success "Keyboard configuration exported"

    return 0

}
