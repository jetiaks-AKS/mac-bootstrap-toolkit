#!/bin/bash

# ==========================================
# macOS Defaults Executor
# ==========================================

DEFAULTS_OBSERVED_PRESENT=false
DEFAULTS_OBSERVED_VALUE=""
DEFAULTS_PREVIEW_CHANGED=false

validate_defaults_config() {
    local config_file="$1"

    if [[ -z "$config_file" || ! -f "$config_file" || ! -r "$config_file" ]]; then
        error "Configuration file not found or unreadable: $config_file"
        return 2
    fi

    if ! awk -F '|' '
        /^[[:space:]]*$/ { next }
        NF != 4 || $1 == "" || $2 == "" { exit 2 }
        $3 == "bool" {
            if ($4 != "0" && $4 != "1" && $4 != "true" && $4 != "false") exit 2
            next
        }
        $3 == "int" {
            if ($4 !~ /^-?[0-9]+$/) exit 2
            next
        }
        $3 == "string" { next }
        { exit 2 }
    ' "$config_file"; then
        error "Invalid macOS configuration: $config_file"
        return 2
    fi

    return 0
}

defaults_native_type() {
    case "$1" in
        bool) echo "Type is boolean" ;;
        int) echo "Type is integer" ;;
        string) echo "Type is string" ;;
        *) return 2 ;;
    esac
}

normalize_defaults_integer() {
    local value="$1"
    local sign=""

    [[ "$value" =~ ^-?[0-9]+$ ]] || return 2

    if [[ "$value" == -* ]]; then
        sign="-"
        value="${value#-}"
    fi

    while [[ ${#value} -gt 1 && "$value" == 0* ]]; do
        value="${value#0}"
    done

    [[ "$value" != 0 ]] || sign=""
    printf '%s%s\n' "$sign" "$value"
}

defaults_values_match() {
    local type="$1"
    local expected="$2"
    local actual="$3"

    case "$type" in
        bool)
            case "$expected" in
                1|true) expected=true ;;
                0|false) expected=false ;;
                *) return 2 ;;
            esac
            case "$actual" in
                1|true) actual=true ;;
                0|false) actual=false ;;
                *) return 2 ;;
            esac
            ;;
        int)
            expected="$(normalize_defaults_integer "$expected")" || return 2
            actual="$(normalize_defaults_integer "$actual")" || return 2
            ;;
        string)
            [[ "$actual" != *$'\n'* ]] || return 2
            ;;
        *) return 2 ;;
    esac

    [[ "$actual" == "$expected" ]]
}

check_defaults_record() {
    local domain="$1"
    local key="$2"
    local type="$3"
    local expected="$4"
    local expected_native_type native_type actual

    DEFAULTS_OBSERVED_PRESENT=false
    DEFAULTS_OBSERVED_VALUE=""

    expected_native_type="$(defaults_native_type "$type")" || return 2

    native_type="$(defaults read-type "$domain" "$key" 2>&1)"
    local type_result=$?

    if [[ $type_result -ne 0 ]]; then
        if [[ "$native_type" == *"does not exist"* ]]; then
            return 1
        fi
        error "Failed to inspect macOS preference: $domain $key"
        return 2
    fi

    if [[ "$native_type" != "$expected_native_type" ]]; then
        error "Incompatible macOS preference type: $domain $key"
        return 2
    fi

    actual="$(defaults read "$domain" "$key" 2>/dev/null)"
    if [[ $? -ne 0 ]]; then
        error "Failed to read macOS preference: $domain $key"
        return 2
    fi

    DEFAULTS_OBSERVED_PRESENT=true
    DEFAULTS_OBSERVED_VALUE="$actual"

    defaults_values_match "$type" "$expected" "$actual"
    local comparison_result=$?

    if [[ $comparison_result -eq 2 ]]; then
        error "Invalid observed macOS preference value: $domain $key"
    fi

    return "$comparison_result"
}

defaults_preview_display_value() {
    local type="$1"
    local value="$2"

    case "$type" in
        bool)
            case "$value" in
                1|true) printf 'true\n' ;;
                0|false) printf 'false\n' ;;
                *) return 2 ;;
            esac
            ;;
        int)
            normalize_defaults_integer "$value"
            ;;
        string)
            [[ "$value" != *[[:cntrl:]]* ]] || return 2
            printf '%s\n' "$value"
            ;;
        *)
            return 2
            ;;
    esac
}

preview_defaults_config() {
    local config_file="$1"
    local domain key type desired
    local record_result
    local current_display desired_display

    validate_defaults_config "$config_file" || return 2
    DEFAULTS_PREVIEW_CHANGED=false

    while IFS='|' read -r domain key type desired; do
        [[ -z "$domain" ]] && continue

        check_defaults_record "$domain" "$key" "$type" "$desired"
        record_result=$?

        [[ $record_result -ne 2 ]] || return 2
        [[ $record_result -ne 0 ]] || continue

        DEFAULTS_PREVIEW_CHANGED=true
        desired_display="$(defaults_preview_display_value "$type" "$desired")" || {
            action "Would change macOS setting: $domain/$key"
            continue
        }

        if [[ "$DEFAULTS_OBSERVED_PRESENT" == false ]]; then
            action "Would change macOS setting: $domain/$key (absent -> $desired_display)"
            continue
        fi

        current_display="$(defaults_preview_display_value "$type" "$DEFAULTS_OBSERVED_VALUE")" || {
            action "Would change macOS setting: $domain/$key"
            continue
        }
        action "Would change macOS setting: $domain/$key ($current_display -> $desired_display)"
    done < "$config_file"

    return 0
}

check_defaults_config() {
    local config_file="$1"
    local configured=true
    local record_result
    local domain key type expected

    validate_defaults_config "$config_file" || return 2

    while IFS='|' read -r domain key type expected; do
        [[ -z "$domain" ]] && continue

        check_defaults_record "$domain" "$key" "$type" "$expected"
        record_result=$?

        [[ $record_result -eq 2 ]] && return 2
        [[ $record_result -eq 0 ]] || configured=false
    done < "$config_file"

    [[ "$configured" == true ]]
}

apply_defaults_config() {
    local config_file="$1"
    local domain key type value
    local record_result
    local write_value

    validate_defaults_config "$config_file" || return 2

    while IFS='|' read -r domain key type value; do
        [[ -z "$domain" ]] && continue

        check_defaults_record "$domain" "$key" "$type" "$value"
        record_result=$?

        [[ $record_result -eq 2 ]] && return 2
        [[ $record_result -eq 0 ]] && continue

        write_value="$value"
        if [[ "$type" == bool ]]; then
            case "$value" in
                1) write_value=true ;;
                0) write_value=false ;;
            esac
        fi

        if ! defaults write "$domain" "$key" "-$type" "$write_value"; then
            error "Failed to configure macOS preference: $domain $key"
            return 2
        fi

        check_defaults_record "$domain" "$key" "$type" "$value"
        record_result=$?

        if [[ $record_result -ne 0 ]]; then
            error "Failed to verify macOS preference: $domain $key"
            return 2
        fi

        MODULE_CHANGED=true
    done < "$config_file"

    return 0
}
