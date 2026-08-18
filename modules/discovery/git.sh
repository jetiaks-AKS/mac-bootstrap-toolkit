#!/bin/bash

# ==========================================
# Git Discovery
# ==========================================

serialize_git_configuration() {

    local output_file="$1"
    local collection_dir="$2"
    local keys=(user.name user.email init.defaultBranch pull.rebase core.editor)
    local index
    local key
    local value

    for index in 0 1 2 3 4; do

        [[ -f "$collection_dir/$index.value" ]] || continue

        IFS= read -r -d '' value < "$collection_dir/$index.value" || return 2
        key="${keys[$index]}"

        git config --file "$output_file" "$key" "$value" || return 2

    done

    git config --file "$output_file" --no-includes --list >/dev/null 2>&1 || return 2

    return 0

}

# ==========================================

discover_git() {

    if ! command -v git >/dev/null 2>&1; then
        error "Git is not installed"
        return 2
    fi

    local output_file="config/generated/git.conf"
    local collection_dir
    local keys=(user.name user.email init.defaultBranch pull.rebase core.editor)
    local index
    local key
    local value_file
    local collection_status
    local value_count
    local value

    action "Exporting Git configuration..."

    collection_dir="$(mktemp -d)" || {
        error "Failed to prepare Git configuration collection"
        return 2
    }

    for index in 0 1 2 3 4; do

        key="${keys[$index]}"
        value_file="$collection_dir/$index.value"

        git config --global --null --get-all "$key" > "$value_file" 2>/dev/null
        collection_status=$?

        case $collection_status in
            0)
                value_count=0
                while IFS= read -r -d '' value; do
                    ((value_count++))
                done < "$value_file"

                if [[ $value_count -ne 1 ]]; then
                    error "Multiple global Git values found for $key"
                    rm -rf "$collection_dir"
                    return 2
                fi
                ;;
            1)
                rm -f "$value_file"
                ;;
            *)
                error "Failed to read global Git configuration: $key"
                rm -rf "$collection_dir"
                return 2
                ;;
        esac

    done

    if ! discovery_publish_file "$output_file" serialize_git_configuration "$collection_dir"; then
        error "Failed to publish Git configuration"
        rm -rf "$collection_dir"
        return 2
    fi

    rm -rf "$collection_dir"

    success "Git configuration exported"
    detail "Configuration saved to:"
    detail "$output_file"

    return 0
}
