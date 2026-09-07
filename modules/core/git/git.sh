#!/bin/bash

# ==========================================
# Git Configuration State
# ==========================================

GIT_CONFIGURATION_FILE="config/generated/git.conf"
GIT_CONFIGURATION_KEYS=(user.name user.email init.defaultBranch pull.rebase core.editor)
GIT_CONFIGURATION_SET=(false false false false false)
GIT_CONFIGURATION_VALUES=("" "" "" "" "")
GIT_CONFIGURATION_MISMATCHES=()
GIT_READ_IS_SET=false
GIT_READ_VALUE=""

# ==========================================
# Read Git Configuration Value
# ==========================================

git_read_configuration_value() {

    local source_type="$1"
    local key="$2"
    local config_file="${3:-}"
    local value_file
    local read_status
    local value_count
    local value

    GIT_READ_IS_SET=false
    GIT_READ_VALUE=""

    value_file="$(mktemp)" || return 2

    case "$source_type" in
        generated)
            git config --file "$config_file" --no-includes --null --get-all "$key" \
                > "$value_file" 2>/dev/null
            ;;
        global)
            git config --global --null --get-all "$key" > "$value_file" 2>/dev/null
            ;;
        *)
            rm -f "$value_file"
            return 2
            ;;
    esac

    read_status=$?

    case $read_status in
        0)
            value_count=0
            while IFS= read -r -d '' value; do
                GIT_READ_VALUE="$value"
                ((value_count++))
            done < "$value_file"

            if [[ $value_count -ne 1 ]]; then
                rm -f "$value_file"
                return 2
            fi
            GIT_READ_IS_SET=true
            ;;
        1)
            ;;
        *)
            rm -f "$value_file"
            return 2
            ;;
    esac

    rm -f "$value_file"
    return 0
}

# ==========================================
# Load Generated Git Configuration
# ==========================================

load_git_configuration() {

    local config_file="${1:-$GIT_CONFIGURATION_FILE}"
    local listed_keys
    local key
    local normalized_key
    local index
    local counts=(0 0 0 0 0)

    if [[ ! -f "$config_file" || ! -r "$config_file" ]]; then
        error "$config_file not found or unreadable; run Discovery again"
        return 2
    fi

    listed_keys="$(git config --file "$config_file" --no-includes --name-only --list 2>/dev/null)" || {
        error "Invalid generated Git configuration; run Discovery again"
        return 2
    }

    while IFS= read -r key; do

        [[ -z "$key" ]] && continue

        normalized_key="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')"

        case "$normalized_key" in
            user.name) index=0 ;;
            user.email) index=1 ;;
            init.defaultbranch) index=2 ;;
            pull.rebase) index=3 ;;
            core.editor) index=4 ;;
            *)
                error "Unknown generated Git configuration key: $key"
                return 2
                ;;
        esac

        counts[$index]=$((counts[$index] + 1))

        if [[ ${counts[$index]} -gt 1 ]]; then
            error "Duplicate generated Git configuration key: $key"
            return 2
        fi

    done <<< "$listed_keys"

    GIT_CONFIGURATION_SET=(false false false false false)
    GIT_CONFIGURATION_VALUES=("" "" "" "" "")

    for index in 0 1 2 3 4; do

        key="${GIT_CONFIGURATION_KEYS[$index]}"

        if ! git_read_configuration_value generated "$key" "$config_file"; then
            error "Failed to read generated Git configuration: $key"
            return 2
        fi

        GIT_CONFIGURATION_SET[$index]="$GIT_READ_IS_SET"
        GIT_CONFIGURATION_VALUES[$index]="$GIT_READ_VALUE"

    done

    if [[ "${GIT_CONFIGURATION_SET[2]}" == true ]] &&
       ! git check-ref-format --branch "${GIT_CONFIGURATION_VALUES[2]}" >/dev/null 2>&1; then
        error "Invalid generated Git default branch"
        return 2
    fi

    if [[ "${GIT_CONFIGURATION_SET[3]}" == true ]]; then
        case "${GIT_CONFIGURATION_VALUES[3]}" in
            true|false|merges|interactive)
                ;;
            *)
                error "Invalid generated Git pull.rebase value"
                return 2
                ;;
        esac
    fi

    return 0
}

# ==========================================
# Check Git
# ==========================================

is_git_installed() {
    command -v git >/dev/null 2>&1
}

# ==========================================
# Check Git Configuration
# ==========================================

inspect_git_configuration() {

    local index
    local key

    load_git_configuration || return 2
    GIT_CONFIGURATION_MISMATCHES=()

    for index in 0 1 2 3 4; do

        key="${GIT_CONFIGURATION_KEYS[$index]}"

        if ! git_read_configuration_value global "$key"; then
            error "Failed to read global Git configuration: $key"
            return 2
        fi

        if [[ "${GIT_CONFIGURATION_SET[$index]}" != "$GIT_READ_IS_SET" ]]; then
            GIT_CONFIGURATION_MISMATCHES+=("$key")
            continue
        fi

        if [[ "$GIT_READ_IS_SET" == true &&
              "${GIT_CONFIGURATION_VALUES[$index]}" != "$GIT_READ_VALUE" ]]; then
            GIT_CONFIGURATION_MISMATCHES+=("$key")
        fi

    done

    [[ ${#GIT_CONFIGURATION_MISMATCHES[@]} -eq 0 ]] && return 0
    return 1
}

check_git_configuration() {

    inspect_git_configuration
}

# ==========================================
# Preview Git Configuration
# ==========================================

preview_git_configuration() {

    local inspection_result
    local key

    inspect_git_configuration
    inspection_result=$?

    case $inspection_result in
        0)
            return 0
            ;;
        1)
            for key in "${GIT_CONFIGURATION_MISMATCHES[@]}"; do
                action "Would configure Git setting: $key"
            done
            return 0
            ;;
        *)
            return 2
            ;;
    esac
}

# ==========================================
# Module Check
# ==========================================

check_git() {

    if is_git_installed; then
        success "Git already installed"
        return 0
    fi

    error "Git is not installed"
    return 2
}

# ==========================================
# Apply Git Configuration
# ==========================================

apply_git_configuration() {

    local index
    local key
    local unset_status

    for index in 0 1 2 3 4; do

        key="${GIT_CONFIGURATION_KEYS[$index]}"

        if [[ "${GIT_CONFIGURATION_SET[$index]}" == true ]]; then
            if ! git config --global "$key" "${GIT_CONFIGURATION_VALUES[$index]}"; then
                error "Failed to configure Git"
                return 2
            fi
            continue
        fi

        if ! git_read_configuration_value global "$key"; then
            error "Failed to read global Git configuration: $key"
            return 2
        fi

        [[ "$GIT_READ_IS_SET" == true ]] || continue

        git config --global --unset-all "$key"
        unset_status=$?

        if [[ $unset_status -ne 0 ]]; then
            if ! git_read_configuration_value global "$key" ||
               [[ "$GIT_READ_IS_SET" == true ]]; then
                error "Failed to configure Git"
                return 2
            fi
        fi

    done

    return 0
}

# ==========================================
# Configure Git
# ==========================================

configure_git() {

    local check_status

    check_git_configuration
    check_status=$?

    case $check_status in
        0)
            success "Git configuration already configured"
            return 0
            ;;
        1)
            ;;
        *)
            return 2
            ;;
    esac

    action "Configuring Git..."

    apply_git_configuration || return 2

    if ! check_git_configuration; then
        error "Git configuration verification failed"
        return 2
    fi

    success "Git configured successfully"
    return 0
}
