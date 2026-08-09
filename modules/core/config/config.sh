#!/bin/bash

# ==========================================
# Config Engine
# ==========================================

# ==========================================
# Get Sections
# ==========================================

config_sections() {

    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    grep '^\[' "$config_file" \
        | sed 's/^\[//;s/\]$//'

}

# ==========================================
# Get Value
# ==========================================

config_get() {

    local config_file="$1"
    local section="$2"
    local key="$3"

    awk -v section="$section" -v key="$key" '

        $0 == "[" section "]" {
            in_section = 1
            next
        }

        /^\[/ {
            in_section = 0
        }

        in_section && $0 ~ "^" key "=" {

            sub("^" key "=\"", "")
            sub("\"$", "")

            print

            exit

        }

    ' "$config_file"

}
