#!/bin/bash

# ==========================================
# macOS Discovery
# ==========================================

macos_defaults_type_name() {

    case "$1" in
        bool) echo "Type is boolean" ;;
        int) echo "Type is integer" ;;
        string) echo "Type is string" ;;
        *) return 2 ;;
    esac

}

macos_collect_preference() {

    local output_file="$1"
    local domain="$2"
    local key="$3"
    local generated_type="$4"
    local expected_native_type
    local native_type
    local value

    expected_native_type="$(macos_defaults_type_name "$generated_type")" || return 2

    native_type="$(defaults read-type "$domain" "$key" 2>&1)"
    local type_result=$?

    if [[ $type_result -ne 0 ]]; then
        if [[ "$native_type" == *"does not exist"* ]]; then
            return 0
        fi

        error "Failed to inspect macOS preference: $domain $key"
        return 2
    fi

    if [[ "$native_type" != "$expected_native_type" ]]; then
        error "Incompatible macOS preference type: $domain $key"
        return 2
    fi

    value="$(defaults read "$domain" "$key" 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        error "Failed to read macOS preference: $domain $key"
        return 2
    fi

    case "$generated_type" in
        bool)
            case "$value" in
                0|1|true|false) ;;
                *)
                    error "Invalid macOS boolean value: $domain $key"
                    return 2
                    ;;
            esac
            ;;
        int)
            if [[ ! "$value" =~ ^-?[0-9]+$ ]]; then
                error "Invalid macOS integer value: $domain $key"
                return 2
            fi
            ;;
        string)
            if [[ "$value" == *$'\n'* ]]; then
                error "Unsupported multiline macOS preference: $domain $key"
                return 2
            fi
            ;;
    esac

    if ! printf '%s|%s|%s|%s\n' \
        "$domain" "$key" "$generated_type" "$value" >> "$output_file"; then
        error "Failed to serialize macOS preference: $domain $key"
        return 2
    fi

    return 0

}

source modules/discovery/macos/finder.sh
source modules/discovery/macos/dock.sh
source modules/discovery/macos/keyboard.sh
source modules/discovery/macos/trackpad.sh
source modules/discovery/macos/screenshots.sh


discover_macos() {

    local discovery_result=0
    local exporter_result

    export_finder_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_dock_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_keyboard_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_trackpad_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    export_screenshots_settings
    exporter_result=$?

    if [[ $exporter_result -gt $discovery_result ]]; then
        discovery_result=$exporter_result
    fi

    echo

    if [[ $discovery_result -eq 0 ]]; then
        success "macOS Discovery completed"
    elif [[ $discovery_result -eq 1 ]]; then
        warning "macOS Discovery completed with warnings"
    else
        error "macOS Discovery completed with errors"
    fi

    return "$discovery_result"

}
