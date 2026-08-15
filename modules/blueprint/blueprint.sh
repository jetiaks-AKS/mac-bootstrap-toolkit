#!/bin/bash

# ==========================================
# Blueprint Selection
# ==========================================

BLUEPRINT_FILE="${BLUEPRINT_FILE:-config/blueprint.conf}"
BLUEPRINT_GENERATED_DIR="${BLUEPRINT_GENERATED_DIR:-config/generated}"

# ==========================================
# Blueprint Exists
# ==========================================

blueprint_exists() {

    local blueprint_file="${1:-$BLUEPRINT_FILE}"

    [[ -f "$blueprint_file" ]]

}

# ==========================================
# Supported Names
# ==========================================

blueprint_category_supported() {

    case "$1" in
        git-configuration|vscode-settings|macos-finder|macos-dock|macos-keyboard|macos-trackpad|macos-screenshots)
            return 0
            ;;
        *)
            return 1
            ;;
    esac

}

blueprint_item_section_supported() {

    case "$1" in
        homebrew-packages|homebrew-casks|app-store|vscode-extensions|workspace-folders|git-repositories)
            return 0
            ;;
        *)
            return 1
            ;;
    esac

}

# ==========================================
# Selection Queries
# ==========================================

blueprint_category_enabled() {

    local category="$1"
    local blueprint_file="${2:-$BLUEPRINT_FILE}"

    blueprint_category_supported "$category" || return 2

    if ! blueprint_exists "$blueprint_file"; then
        return 0
    fi

    local value

    value="$(awk -v category="$category" '
        $0 == "[categories]" {
            in_categories = 1
            next
        }

        /^\[/ {
            in_categories = 0
        }

        in_categories && $0 ~ "^" category "=" {
            sub("^" category "=\"", "")
            sub("\"$", "")
            print
            exit
        }
    ' "$blueprint_file")"

    case "$value" in
        true)
            return 0
            ;;
        false)
            return 1
            ;;
        *)
            return 2
            ;;
    esac

}

blueprint_selected_items() {

    local section="$1"
    local blueprint_file="${2:-$BLUEPRINT_FILE}"

    blueprint_item_section_supported "$section" || return 2
    blueprint_exists "$blueprint_file" || return 1

    awk -v target="$section" '
        $0 == "[" target "]" {
            in_section = 1
            next
        }

        /^\[/ {
            in_section = 0
        }

        in_section && $0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]*#/ {
            print
        }
    ' "$blueprint_file"

}

blueprint_item_selected() {

    local section="$1"
    local item="$2"
    local blueprint_file="${3:-$BLUEPRINT_FILE}"

    blueprint_item_section_supported "$section" || return 2

    if ! blueprint_exists "$blueprint_file"; then
        return 0
    fi

    blueprint_selected_items "$section" "$blueprint_file" |
        grep -Fxq -- "$item"

}

# ==========================================
# Syntax Validation
# ==========================================

blueprint_validate_syntax() {

    local blueprint_file="${1:-$BLUEPRINT_FILE}"
    local validation_output
    local validation_result

    validation_output="$(awk '
        BEGIN {
            sections["categories"] = 1
            sections["homebrew-packages"] = 1
            sections["homebrew-casks"] = 1
            sections["app-store"] = 1
            sections["vscode-extensions"] = 1
            sections["workspace-folders"] = 1
            sections["git-repositories"] = 1

            categories["git-configuration"] = 1
            categories["vscode-settings"] = 1
            categories["macos-finder"] = 1
            categories["macos-dock"] = 1
            categories["macos-keyboard"] = 1
            categories["macos-trackpad"] = 1
            categories["macos-screenshots"] = 1
        }

        function invalid(message) {
            print message
            has_errors = 1
        }

        /^[[:space:]]*$/ || /^[[:space:]]*#/ {
            next
        }

        /^\[/ {
            if ($0 !~ /^\[[a-z-]+\]$/) {
                invalid("Malformed Blueprint section at line " NR)
                current_section = ""
                next
            }

            current_section = substr($0, 2, length($0) - 2)

            if (!(current_section in sections)) {
                invalid("Unknown Blueprint section: " current_section)
                next
            }

            section_count[current_section]++

            if (section_count[current_section] > 1) {
                invalid("Duplicate Blueprint section: " current_section)
            }

            next
        }

        current_section == "" {
            invalid("Blueprint data outside a section at line " NR)
            next
        }

        current_section == "categories" {
            separator = index($0, "=")
            key = separator ? substr($0, 1, separator - 1) : $0

            if (!(key in categories)) {
                invalid("Unknown Blueprint category: " key)
                next
            }

            if ($0 != key "=\"true\"" && $0 != key "=\"false\"") {
                invalid("Invalid boolean for Blueprint category: " key)
                next
            }

            category_count[key]++

            if (category_count[key] > 1) {
                invalid("Duplicate Blueprint category: " key)
            }

            next
        }

        {
            if (index($0, "=") != 0) {
                invalid("Assignment syntax is not allowed in Blueprint item sections at line " NR)
                next
            }

            if ($0 ~ /^[[:space:]]/ || $0 ~ /[[:space:]]$/) {
                invalid("Blueprint item has leading or trailing whitespace at line " NR)
                next
            }

            if ($0 ~ /[[:space:]]#/) {
                invalid("Inline Blueprint comments are not supported at line " NR)
                next
            }

            item_key = current_section SUBSEP $0
            item_count[item_key]++

            if (item_count[item_key] > 1) {
                invalid("Duplicate Blueprint item in " current_section ": " $0)
            }
        }

        END {
            for (section in sections) {
                if (section_count[section] != 1) {
                    invalid("Missing Blueprint section: " section)
                }
            }

            for (category in categories) {
                if (category_count[category] != 1) {
                    invalid("Missing Blueprint category: " category)
                }
            }

            exit(has_errors ? 2 : 0)
        }
    ' "$blueprint_file")"
    validation_result=$?

    if [[ -n "$validation_output" ]]; then
        while IFS= read -r message; do
            error "$message"
        done <<< "$validation_output"
    fi

    return "$validation_result"

}

# ==========================================
# Generated State Validation
# ==========================================

blueprint_generated_file() {

    case "$1" in
        homebrew-packages)
            echo "$BLUEPRINT_GENERATED_DIR/brew-packages.conf"
            ;;
        homebrew-casks)
            echo "$BLUEPRINT_GENERATED_DIR/brew-casks.conf"
            ;;
        app-store)
            echo "$BLUEPRINT_GENERATED_DIR/appstore.conf"
            ;;
        vscode-extensions)
            echo "$BLUEPRINT_GENERATED_DIR/vscode-extensions.conf"
            ;;
        workspace-folders)
            echo "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"
            ;;
        git-repositories)
            echo "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
            ;;
        *)
            return 1
            ;;
    esac

}

blueprint_generated_has_item() {

    local section="$1"
    local item="$2"
    local generated_file

    generated_file="$(blueprint_generated_file "$section")" || return 1
    [[ -f "$generated_file" ]] || return 1

    case "$section" in
        homebrew-packages|homebrew-casks|vscode-extensions)
            grep -Fxq -- "$item" "$generated_file"
            ;;
        app-store|workspace-folders)
            awk -F '|' -v item="$item" '$1 == item { found = 1 } END { exit(found ? 0 : 1) }' \
                "$generated_file"
            ;;
        git-repositories)
            grep -Fxq -- "[$item]" "$generated_file"
            ;;
    esac

}

blueprint_validate_repository_identifiers() {

    local repositories_file="$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"

    [[ -f "$repositories_file" ]] || return 0

    local duplicate_identifiers

    duplicate_identifiers="$(awk '
        /^\[[^]]+\]$/ {
            identifier = substr($0, 2, length($0) - 2)
            count[identifier]++

            if (count[identifier] == 2) {
                print identifier
            }
        }
    ' "$repositories_file")"

    if [[ -z "$duplicate_identifiers" ]]; then
        return 0
    fi

    while IFS= read -r identifier; do
        error "Ambiguous generated repository identifier: $identifier"
    done <<< "$duplicate_identifiers"

    return 2

}

blueprint_validate_selected_items() {

    local blueprint_file="${1:-$BLUEPRINT_FILE}"
    local validation_result=0
    local section
    local item

    for section in \
        homebrew-packages \
        homebrew-casks \
        app-store \
        vscode-extensions \
        workspace-folders \
        git-repositories; do

        while IFS= read -r item; do
            [[ -z "$item" ]] && continue

            if ! blueprint_generated_has_item "$section" "$item"; then
                warning "Stale Blueprint item in $section: $item"
                validation_result=1
            fi
        done < <(blueprint_selected_items "$section" "$blueprint_file")

    done

    return "$validation_result"

}

# ==========================================
# Blueprint Validation
# ==========================================

blueprint_validate() {

    local blueprint_file="${1:-$BLUEPRINT_FILE}"
    local validation_result=0
    local result

    if ! blueprint_exists "$blueprint_file"; then
        return 0
    fi

    blueprint_validate_syntax "$blueprint_file" || return 2

    blueprint_validate_repository_identifiers
    result=$?

    if [[ $result -gt $validation_result ]]; then
        validation_result=$result
    fi

    blueprint_validate_selected_items "$blueprint_file"
    result=$?

    if [[ $result -gt $validation_result ]]; then
        validation_result=$result
    fi

    return "$validation_result"

}
