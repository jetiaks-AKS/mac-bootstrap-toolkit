#!/bin/bash

# Shared scalar contract for macOS Discovery and consumers. No generated code.
macos_record_bytes_valid() {
    local bytes
    # Check before shell/awk string parsing: macOS awk can silently lose NUL.
    bytes="$(LC_ALL=C od -An -v -tu1 "$1")" || return 2
    LC_ALL=C awk '{ for (i=1; i<=NF; i++)
        if (($i < 32 && $i != 10) || $i == 127) exit 2
    }' <<< "$bytes"
}

validate_defaults_config() {
    local config_file="$1"
    local category="${2:-}"

    if [[ ! -f "$config_file" || ! -r "$config_file" ]]; then
        error "Configuration file not found or unreadable: $config_file"
        return 2
    fi

    if ! macos_record_bytes_valid "$config_file" || ! LC_ALL=C awk -F '|' -v category="$category" '
        BEGIN {
            allowed["finder", "NSGlobalDomain", "AppleShowAllExtensions"] = "bool"
            allowed["finder", "com.apple.finder", "ShowPathbar"] = "bool"
            allowed["finder", "com.apple.finder", "ShowStatusBar"] = "bool"
            allowed["finder", "com.apple.finder", "FXPreferredViewStyle"] = "string"
            allowed["finder", "com.apple.finder", "FXDefaultSearchScope"] = "string"
            allowed["finder", "com.apple.finder", "_FXSortFoldersFirst"] = "bool"
            allowed["finder", "com.apple.finder", "FXRemoveOldTrashItems"] = "bool"
            allowed["dock", "com.apple.dock", "autohide"] = "bool"
            allowed["dock", "com.apple.dock", "show-recents"] = "bool"
            allowed["dock", "com.apple.dock", "tilesize"] = "int"
            allowed["dock", "com.apple.dock", "magnification"] = "bool"
            allowed["dock", "com.apple.dock", "largesize"] = "int"
            allowed["keyboard", "NSGlobalDomain", "KeyRepeat"] = "int"
            allowed["keyboard", "NSGlobalDomain", "InitialKeyRepeat"] = "int"
            allowed["trackpad", "com.apple.AppleMultitouchTrackpad", "Clicking"] = "bool"
            allowed["trackpad", "NSGlobalDomain", "com.apple.trackpad.scaling"] = "int"
            allowed["trackpad", "com.apple.AppleMultitouchTrackpad", "TrackpadRightClick"] = "bool"
            allowed["screenshots", "com.apple.screencapture", "location"] = "string"
            if (category !~ /^(finder|dock|keyboard|trackpad|screenshots)$/) exit 2
        }
        /^ *$/ { next }
        NF != 4 || $1 == "" || $2 == "" { exit 2 }
        { if (seen[$1, $2]++) exit 2 }
        allowed[category, $1, $2] != $3 { exit 2 }
        category == "screenshots" {
            # Only absolute paths or leading ~/; no shell syntax or traversal.
            if ($4 !~ /^(\/|~\/)/ || $4 ~ /[$`\\]/ || $4 ~ /\/\// ||
                $4 ~ /(^|\/)\.\.?($|\/)/) exit 2
        }
        $3 == "bool" {
            if ($4 !~ /^(0|1|true|false)$/) exit 2
            next
        }
        $3 == "int" { if ($4 !~ /^-?[0-9]+$/) exit 2; next }
        $3 == "string" { next }
        { exit 2 }
    ' "$config_file"; then
        error "Invalid macOS configuration${category:+ ($category)}: $config_file"
        return 2
    fi
    return 0
}

# Preserve raw bytes until validated; remove only the command output newline.
macos_read_scalar() {
    local value_file
    MACOS_DEFAULTS_VALUE=""
    value_file="$(mktemp)" || return 2
    if ! defaults read "$1" "$2" > "$value_file" 2>/dev/null ||
       ! macos_record_bytes_valid "$value_file" ||
       ! LC_ALL=C awk 'NR > 1 || /\|/ { exit 2 }' "$value_file"; then
        rm -f "$value_file"
        return 2
    fi
    IFS= read -r MACOS_DEFAULTS_VALUE < "$value_file" || :
    rm -f "$value_file" || return 2
    return 0
}
