#!/bin/bash

discover_ssh_configuration() {
    local directory="$HOME/.ssh" source_file="$HOME/.ssh/config"
    local payload
    local directory_before directory_after
    local before after
    local metrics eligible excluded structural status result

    payload="$(mktemp)" || return 2
    status=""

    if [[ "$HOME" != /* || ! -d "$HOME" || -L "$HOME" ||
          "$(stat -f '%u' "$HOME" 2>/dev/null)" != "$(id -u)" ]]; then
        status=external
    elif [[ ! -e "$directory" && ! -L "$directory" ]]; then
        status=absent-directory
    elif [[ -L "$directory" ]]; then
        status=external
    elif [[ ! -d "$directory" ]]; then
        rm -f "$payload"
        error "Unexpected SSH source type"
        return 2
    elif [[ "$(stat -f '%u' "$directory" 2>/dev/null)" != "$(id -u)" ]]; then
        status=external
    elif [[ "$(stat -f '%Lp' "$directory" 2>/dev/null)" != 700 ]]; then
        status=external
    elif [[ ! -r "$directory" || ! -x "$directory" ]]; then
        rm -f "$payload"
        error "SSH source is unreadable"
        return 2
    elif [[ ! -e "$source_file" && ! -L "$source_file" ]]; then
        status=absent-config
    elif [[ -L "$source_file" ]]; then
        status=external
    elif [[ ! -f "$source_file" ]]; then
        rm -f "$payload"
        error "Unexpected SSH source type"
        return 2
    elif [[ "$(stat -f '%u' "$source_file" 2>/dev/null)" != "$(id -u)" ]]; then
        status=external
    elif [[ "$(stat -f '%Lp' "$source_file" 2>/dev/null)" != 600 &&
            "$(stat -f '%Lp' "$source_file" 2>/dev/null)" != 400 &&
            "$(stat -f '%Lp' "$source_file" 2>/dev/null)" != 640 &&
            "$(stat -f '%Lp' "$source_file" 2>/dev/null)" != 644 ]]; then
        status=external
    elif [[ ! -r "$source_file" ]]; then
        rm -f "$payload"
        error "SSH source is unreadable"
        return 2
    else
        directory_before="$(stat -f '%d:%i:%u:%Lp' "$directory" 2>/dev/null)" || {
            rm -f "$payload"
            return 2
        }

        before="$(stat -f '%d:%i:%z:%m:%c:%Lp' "$source_file" 2>/dev/null)" || {
            rm -f "$payload"
            return 2
        }

        metrics="$(ssh_config_parse "$source_file" "$payload" source)"
        result=$?

        after="$(stat -f '%d:%i:%z:%m:%c:%Lp' "$source_file" 2>/dev/null)" || result=2
        directory_after="$(stat -f '%d:%i:%u:%Lp' "$directory" 2>/dev/null)" || result=2

        if [[ $result -ne 0 ||
              "$before" != "$after" ||
              "$directory_before" != "$directory_after" ||
              -L "$directory" ||
              -L "$source_file" ]]; then
            rm -f "$payload"
            error "SSH source changed or is malformed"
            return 2
        fi

        read -r eligible excluded structural <<< "$metrics"

        if [[ $structural -ne 0 ]]; then
            : > "$payload"
            eligible=0
            excluded=1
            status=unsupported
        elif [[ $eligible -gt 0 && $excluded -gt 0 ]]; then
            status=partial
        elif [[ $eligible -gt 0 ]]; then
            status=ready
        elif [[ $excluded -gt 0 ]]; then
            status=unsupported
        else
            status=empty
        fi
    fi

    # Revalidate the complete observed source immediately before publication.
    if [[ -n "$before" ]]; then
        after="$(stat -f '%d:%i:%z:%m:%c:%Lp' "$source_file" 2>/dev/null)" || {
            rm -f "$payload"
            return 2
        }

        directory_after="$(stat -f '%d:%i:%u:%Lp' "$directory" 2>/dev/null)" || {
            rm -f "$payload"
            return 2
        }

        if [[ "$before" != "$after" ||
              "$directory_before" != "$directory_after" ||
              -L "$directory" ||
              -L "$source_file" ]]; then
            rm -f "$payload"
            error "SSH source changed"
            return 2
        fi
    fi

    excluded="${excluded:-0}"

    (
        umask 077
        discovery_publish_file \
            "$SSH_SNAPSHOT_FILE" \
            ssh_snapshot_write \
            "$status" \
            "$excluded" \
            "$payload"
    )
    result=$?

    rm -f "$payload"

    [[ $result -eq 0 ]] || {
        error "Failed to publish SSH snapshot"
        return 2
    }

    case "$status" in
        partial)
            warning "SSH source excluded $excluded profiles"
            return 1
            ;;
        unsupported|external)
            warning "SSH source is not eligible for restoration"
            return 1
            ;;
        *)
            success "SSH configuration inspected"
            return 0
            ;;
    esac
}
