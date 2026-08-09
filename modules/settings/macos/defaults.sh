#!/bin/bash

# ==========================================
# macOS Defaults Executor
# ==========================================

check_defaults_config() {

    local config_file="$1"

    if [[ -z "$config_file" ]]; then
        error "Configuration file not specified"
        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        error "Configuration file not found: $config_file"
        return 1
    fi

    local configured=true

    while IFS='|' read -r domain key type expected; do

        [[ -z "$domain" ]] && continue

        if [[ -z "$key" || -z "$type" ]]; then
            warning "Invalid configuration entry: $domain|$key|$type|$expected"
            configured=false
            continue
        fi

        local actual

        actual="$(defaults read "$domain" "$key" 2>/dev/null)"

        if [[ "$actual" != "$expected" ]]; then
            configured=false
        fi

    done < "$config_file"

    if $configured; then
        return 0
    fi

    return 1

}

# ==========================================
# Apply macOS Defaults
# ==========================================

apply_defaults_config() {

    local config_file="$1"

    if [[ -z "$config_file" ]]; then
        error "Configuration file not specified"
        return 1
    fi

    if [[ ! -f "$config_file" ]]; then
        error "Configuration file not found: $config_file"
        return 1
    fi

    local applied=true

    while IFS='|' read -r domain key type value; do

        [[ -z "$domain" ]] && continue

        if [[ -z "$key" || -z "$type" ]]; then
            warning "Skipping invalid configuration entry: $domain|$key|$type|$value"
            applied=false
            continue
        fi

        case "$type" in

            bool)

                case "$value" in
                    1)
                        value="true"
                        ;;
                    0)
                        value="false"
                        ;;
                    true|false)
                        ;;
                    *)
                        warning "Invalid boolean value: $value"
                        applied=false
                        continue
                        ;;
                esac

                defaults write "$domain" "$key" -bool "$value" || applied=false
                ;;

            int)
                defaults write "$domain" "$key" -int "$value" || applied=false
                ;;

            float)
                defaults write "$domain" "$key" -float "$value" || applied=false
                ;;

            string)
                defaults write "$domain" "$key" -string "$value" || applied=false
                ;;

            *)
                warning "Unsupported defaults type: $type"
                applied=false
                continue
                ;;

        esac

    done < "$config_file"

    if $applied; then
        return 0
    fi

    return 1

}
