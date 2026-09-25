#!/bin/bash

BUNDLE_HELPER="modules/bundle/bundle.py"

bundle_prompt() {
    local answer
    printf '%s ' "$1"
    IFS= read -r answer || return 1
    [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

bundle_offer_age() {
    command -v age >/dev/null 2>&1 && return 0
    if ! command -v brew >/dev/null 2>&1; then
        error "age is required for secure SSH identities; Homebrew is unavailable"
        return 2
    fi
    bundle_prompt "Install age with Homebrew now? [y/N]" || return 1
    brew install age || return 2
    command -v age >/dev/null 2>&1 || return 2
}

bundle_stage() {
    local temporary
    temporary="$(mktemp -d "${TMPDIR:-/tmp}/mbt-bundle.XXXXXX")" || return 2
    (cd "$temporary" && pwd -P)
}

bundle_capture() (
    umask 077
    local stage result output timestamp
    stage="$(bundle_stage)" || return 2
    trap 'rm -rf "$stage"' EXIT
    mkdir -m 700 "$stage/generated" || return 2
    info "Scanning supported state into private Capture staging."
    BLUEPRINT_FILE="$stage/blueprint.conf" BLUEPRINT_GENERATED_DIR="$stage/generated" \
        ./bootstrap.sh --discover
    result=$?
    [[ $result -le 1 ]] || return "$result"
    local tool inventory
    for tool in mas code; do
        case "$tool" in
            mas) inventory="$stage/generated/appstore.conf" ;;
            code) inventory="$stage/generated/vscode-extensions.conf" ;;
        esac
        if [[ ! -f "$inventory" && ! -L "$inventory" ]] &&
           ! command -v "$tool" >/dev/null 2>&1; then
            warning "$tool is unavailable; its application inventory was not captured."
            bundle_prompt "Continue Capture with no $tool items? [y/N]" || return 1
            (umask 077; : > "$inventory") || return 2
        fi
    done
    BUNDLE_CAPTURE_ACTIVE=true BLUEPRINT_FILE="$stage/blueprint.conf" BLUEPRINT_GENERATED_DIR="$stage/generated" \
        ./bootstrap.sh --blueprint || return 2
    if [[ ! -f "$stage/blueprint.conf" ]]; then
        info "Capture cancelled before selection was saved."
        return 0
    fi
    BLUEPRINT_FILE="$stage/blueprint.conf" BLUEPRINT_GENERATED_DIR="$stage/generated" \
        ./bootstrap.sh --dry-run
    result=$?
    [[ $result -le 1 ]] || return "$result"
    python3 "$BUNDLE_HELPER" check-portability "$stage" "$HOME" || return 2
    if [[ -e "$HOME/.ssh" || -L "$HOME/.ssh" ]] &&
       bundle_prompt "Select SSH identities for encrypted Secure Credentials? [y/N]"; then
        if bundle_offer_age; then
            ./scripts/ssh-identity-migrate.sh capture-export --output "$stage/secure.age"
            result=$?
            [[ $result -le 1 ]] || return "$result"
        else
            warning "Secure SSH export unavailable or declined."
            bundle_prompt "Continue Capture without SSH identities? [y/N]" || return 1
        fi
    fi
    timestamp="$(date +%Y%m%d-%H%M%S)" || return 2
    [[ ! -L exports ]] || { error "Unsafe exports directory"; return 2; }
    if [[ -e exports ]]; then
        [[ -d exports && "$(stat -f '%u' exports 2>/dev/null)" == "$(id -u)" ]] || {
            error "Unsafe exports directory"
            return 2
        }
    else
        mkdir -m 700 exports || return 2
    fi
    chmod 700 exports || return 2
    output="$(cd exports && pwd -P)/bootstrap-$timestamp.mbt"
    python3 "$BUNDLE_HELPER" pack "$stage" "$output" "$HOME" || return 2
    success "Bootstrap Bundle created: $output"
    info "Transfer this one private Bundle to the new Mac."
)

bundle_choose_categories() {
    local stage="$1" answer index state
    local -a names=("Applications" "Homebrew" "macOS Settings" "Shell" "Git" "SSH Configuration" "Workspace")
    local -a disabled=()
    local -a groups=()
    BUNDLE_SECURE_SELECTED=true
    [[ -f "$stage/secure.age" ]] || BUNDLE_SECURE_SELECTED=false
    while true; do
        groups=()
        for index in "${disabled[@]}"; do groups+=("${names[$index]}"); done
        echo "Restore selection:"
        python3 "$BUNDLE_HELPER" summary "$stage" "$BUNDLE_SECURE_SELECTED" "${groups[@]}" || return 2
        printf 'Enter=continue, C=change categories, Q=cancel: '
        IFS= read -r answer || return 3
        case "$answer" in
            "") break ;;
            [qQ]) return 3 ;;
            [cC])
                for ((index=0; index<${#names[@]}; index++)); do
                    state=x
                    [[ " ${disabled[*]} " != *" $index "* ]] || state=" "
                    printf '  %d [%s] %s\n' "$((index+1))" "$state" "${names[$index]}"
                done
                printf '  8 [%s] Secure Credentials\n' "$([[ "$BUNDLE_SECURE_SELECTED" == true ]] && echo x || echo ' ')"
                printf 'Enter numbers to disable (comma separated), or Q: '
                IFS= read -r answer || return 3
                [[ "$answer" != [qQ] ]] || return 3
                [[ "$answer" =~ ^[1-8](,[1-8])*$ ]] || { warning "Use numbers 1-8."; continue; }
                local token
                IFS=, read -r -a tokens <<< "$answer"
                for token in "${tokens[@]}"; do
                    if [[ "$token" == 8 ]]; then
                        BUNDLE_SECURE_SELECTED=false
                    else
                        disabled+=("$((token-1))")
                    fi
                done
                ;;
            *) warning "Choose Enter, C or Q." ;;
        esac
    done
    groups=()
    for index in "${disabled[@]}"; do groups+=("${names[$index]}"); done
    python3 "$BUNDLE_HELPER" narrow "$stage" "${groups[@]}" || return 2
}

bundle_restore() (
    umask 077
    local input="$1" stage result secure_selected
    [[ -n "$input" ]] || { error "Restore requires a Bundle path"; return 2; }
    stage="$(bundle_stage)" || return 2
    trap 'rm -rf "$stage"' EXIT
    python3 "$BUNDLE_HELPER" unpack "$input" "$stage" "$HOME" || return 2
    python3 "$BUNDLE_HELPER" recover || return 2
    bundle_choose_categories "$stage"
    result=$?
    if [[ $result -eq 3 ]]; then info "Restore cancelled."; return 0; fi
    [[ $result -eq 0 ]] || return "$result"
    secure_selected="$BUNDLE_SECURE_SELECTED"
    BUNDLE_RESTORE_PREVIEW=true BLUEPRINT_FILE="$stage/blueprint.conf" BLUEPRINT_GENERATED_DIR="$stage/generated" \
        ./bootstrap.sh --dry-run
    result=$?
    [[ $result -le 1 ]] || return "$result"
    bundle_prompt "Apply this selection with Bootstrap? [y/N]" || {
        info "Restore cancelled before publication."
        return 0
    }
    python3 "$BUNDLE_HELPER" publish "$stage" || return 2
    env -u BLUEPRINT_FILE -u BLUEPRINT_GENERATED_DIR -u SSH_SNAPSHOT_FILE \
        -u ZSH_SNAPSHOT_FILE BUNDLE_RESTORE_ACTIVE=true ./bootstrap.sh --bootstrap
    result=$?
    if [[ $result -gt 1 ]]; then
        error "Normal Bootstrap did not complete; secure identities were not imported."
        return "$result"
    fi
    if [[ "$secure_selected" == true ]]; then
        bundle_offer_age
        local age_result=$?
        if [[ $age_result -ne 0 ]]; then
            warning "Normal Bootstrap completed; secure SSH import remains pending."
            return "$age_result"
        fi
        info "Secure Credentials: enter the Bundle passphrase created during Capture, not an SSH-key passphrase."
        ./scripts/ssh-identity-migrate.sh import --input "$stage/secure.age"
        local import_result=$?
        if [[ $import_result -ne 0 ]]; then
            warning "Normal Bootstrap completed; secure SSH import remains pending."
            return "$import_result"
        fi
    fi
    success "Restore completed. Future bs workflow runs from ordinary local state."
    return "$result"
)
