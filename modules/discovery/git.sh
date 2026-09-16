#!/bin/bash

serialize_git_configuration() {
    local output_file="$1" index
    : > "$output_file" || return 2
    for index in 0 1 2 3 4 5 6; do
        [[ "${GIT_DISCOVERY_SET[$index]}" == true ]] || continue
        git config --file "$output_file" "${GIT_CONFIGURATION_KEYS[$index]}" \
            "${GIT_DISCOVERY_VALUES[$index]}" || return 2
    done
    git config --file "$output_file" --no-includes --list >/dev/null 2>&1 || return 2
}

discover_git() {
    local output_file="config/generated/git.conf"
    local index key value result warning_result=0
    if ! command -v git >/dev/null 2>&1; then
        error "Git is not installed"
        return 2
    fi
    action "Exporting Git configuration..."
    git_global_observe source
    result=$?
    if [[ $result -eq 2 ]]; then
        error "Failed to inspect direct global Git configuration"
        return 2
    fi
    GIT_DISCOVERY_SET=(false false false false false false false)
    GIT_DISCOVERY_VALUES=("" "" "" "" "" "" "")
    if [[ $result -eq 1 ]]; then
        warning "Global Git configuration is externally managed; exporting empty snapshot"
        warning_result=1
    else
        for index in 0 1 2 3 4 5 6; do
            [[ ${GIT_GLOBAL_COUNTS[$index]} -gt 0 ]] || continue
            key="${GIT_CONFIGURATION_KEYS[$index]}"
            if [[ ${GIT_GLOBAL_COUNTS[$index]} -ne 1 ]]; then
                warning "Multiple direct global Git values excluded: $key"
                warning_result=1
                continue
            fi
            value="${GIT_GLOBAL_VALUES[$index]}"
            case "$key" in
                pull.rebase)
                    if [[ "$value" != merges && "$value" != interactive ]]; then
                        value="$(git_configuration_normalize_boolean "$value")" || value=""
                    fi
                    ;;
                user.useConfigOnly)
                    value="$(git_configuration_normalize_boolean "$value")" || value=""
                    ;;
                pull.ff)
                    if [[ "$value" != only ]]; then
                        value="$(git_configuration_normalize_boolean "$value")" || value=""
                    fi
                    ;;
            esac
            if ! git_configuration_validate_value "$key" "$value" ||
               { [[ "$key" == core.editor ]] &&
                 ! git_configuration_editor_available "$value"; }; then
                warning "Unsupported direct global Git setting excluded: $key"
                warning_result=1
                continue
            fi
            GIT_DISCOVERY_SET[$index]=true
            GIT_DISCOVERY_VALUES[$index]="$value"
        done
    fi
    if ! discovery_publish_file "$output_file" serialize_git_configuration; then
        error "Failed to publish Git configuration"
        return 2
    fi
    [[ $warning_result -eq 0 ]] || return 1
    success "Git configuration exported"
    detail "Configuration saved to: $output_file"
    return 0
}
