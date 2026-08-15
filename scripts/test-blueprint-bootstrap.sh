#!/bin/bash

# ==========================================
# Blueprint Bootstrap Filtering Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

BLUEPRINT_FILE="$TEST_ROOT/blueprint.conf"
BLUEPRINT_GENERATED_DIR="$TEST_ROOT/generated"
HOME="$TEST_ROOT/home"
VERBOSE=false
MODULE_CHANGED=false
TEST_FAILURES=0
PROCESSED_ITEMS=""

source "$PROJECT_ROOT/modules/core/common/common.sh"

log() { :; }
section() { :; }
action() { :; }
detail() { :; }
info() { :; }
success() { :; }
warning() { :; }
error() { :; }

source "$PROJECT_ROOT/modules/core/config/config.sh"
source "$PROJECT_ROOT/modules/blueprint/blueprint.sh"
source "$PROJECT_ROOT/modules/apps/brew-packages.sh"
source "$PROJECT_ROOT/modules/apps/brew-casks.sh"
source "$PROJECT_ROOT/modules/apps/appstore.sh"
source "$PROJECT_ROOT/modules/vscode/extensions.sh"
source "$PROJECT_ROOT/modules/bootstrap/workspace/folders.sh"
source "$PROJECT_ROOT/modules/bootstrap/workspace/repositories.sh"

command() {
    return 0
}

brew() {
    if [[ "$1" == list ]]; then
        return 1
    fi

    PROCESSED_ITEMS="${PROCESSED_ITEMS}${PROCESSED_ITEMS:+ }$2"
}

mas() {
    return 0
}

code() {
    return 0
}

is_cask_installed() {
    return 1
}

install_brew_cask() {
    PROCESSED_ITEMS="${PROCESSED_ITEMS}${PROCESSED_ITEMS:+ }$1"
}

install_appstore_app() {
    PROCESSED_ITEMS="${PROCESSED_ITEMS}${PROCESSED_ITEMS:+ }$1"
}

install_vscode_extension() {
    PROCESSED_ITEMS="${PROCESSED_ITEMS}${PROCESSED_ITEMS:+ }$1"
}

repository_verify() {
    PROCESSED_ITEMS="${PROCESSED_ITEMS}${PROCESSED_ITEMS:+ }$(basename "$1")"
}

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1"
    ((TEST_FAILURES++))
}

expect_processed() {
    local label="$1"
    local expected="$2"

    shift 2
    PROCESSED_ITEMS=""
    MODULE_CHANGED=false

    "$@" >/dev/null

    if [[ "$PROCESSED_ITEMS" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label (expected '$expected', got '$PROCESSED_ITEMS')"
    fi
}

expect_status() {
    local label="$1"
    local expected="$2"

    shift 2
    "$@" >/dev/null
    local actual=$?

    if [[ $actual -eq $expected ]]; then
        pass "$label -> $actual"
    else
        fail "$label (expected $expected, got $actual)"
    fi
}

run_bootstrap_orchestration() {
    local orchestration

    orchestration="$(awk '
        /^[[:space:]]*blueprint_result=0$/ {
            capture = 1
        }

        capture && /^[[:space:]]*;;$/ {
            exit
        }

        capture {
            print
        }
    ' "$PROJECT_ROOT/bootstrap.sh")"

    [[ -n "$orchestration" ]] || return 2
    eval "$orchestration"
}

reset_orchestration() {
    MODULES_CHECKED=0
    INSTALLED_COUNT=0
    SKIPPED_COUNT=0
    WARNING_COUNT=0
    ERROR_COUNT=0
    PROCESSED_ITEMS=""
}

record_orchestration_step() {
    PROCESSED_ITEMS="${PROCESSED_ITEMS}${PROCESSED_ITEMS:+ }$1"
}

bootstrap_workspace() {
    record_orchestration_step workspace
}

configure_git() {
    record_orchestration_step git-configuration
}

apply_vscode_settings() {
    record_orchestration_step vscode-settings
}

apply_macos_settings() {
    record_orchestration_step macos-settings
}

write_blueprint() {
    local include_items="${1:-true}"

    {
        echo '[categories]'
        echo 'git-configuration="true"'
        echo 'vscode-settings="true"'
        echo 'macos-finder="true"'
        echo 'macos-dock="true"'
        echo 'macos-keyboard="true"'
        echo 'macos-trackpad="true"'
        echo 'macos-screenshots="true"'
        echo
        echo '[homebrew-packages]'
        [[ "$include_items" == true ]] && echo 'selected-package'
        echo
        echo '[homebrew-casks]'
        [[ "$include_items" == true ]] && echo 'selected-cask'
        echo
        echo '[app-store]'
        [[ "$include_items" == true ]] && echo '111'
        echo
        echo '[vscode-extensions]'
        [[ "$include_items" == true ]] && echo 'selected.extension'
        echo
        echo '[workspace-folders]'
        [[ "$include_items" == true ]] && echo 'SelectedFolder'
        echo
        echo '[git-repositories]'
        [[ "$include_items" == true ]] && echo 'selected-repository'
    } > "$BLUEPRINT_FILE"
}

write_generated_state() {
    mkdir -p "$BLUEPRINT_GENERATED_DIR/workspace" "$HOME"

    printf '%s\n' selected-package unselected-package > \
        "$BLUEPRINT_GENERATED_DIR/brew-packages.conf"
    printf '%s\n' selected-cask unselected-cask > \
        "$BLUEPRINT_GENERATED_DIR/brew-casks.conf"
    printf '%s\n' '111|Selected App' '222|Unselected App' > \
        "$BLUEPRINT_GENERATED_DIR/appstore.conf"
    printf '%s\n' selected.extension unselected.extension > \
        "$BLUEPRINT_GENERATED_DIR/vscode-extensions.conf"
    printf '%s\n' 'SelectedFolder|workspace' 'UnselectedFolder|workspace' > \
        "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"

    {
        echo '[selected-repository]'
        echo "PATH=\"$HOME/SelectedFolder/selected-repository\""
        echo 'REMOTE="git@example.com:selected/repository.git"'
        echo 'CURRENT_BRANCH="main"'
        echo
        echo '[unselected-repository]'
        echo "PATH=\"$HOME/UnselectedFolder/unselected-repository\""
        echo 'REMOTE="git@example.com:unselected/repository.git"'
        echo 'CURRENT_BRANCH="main"'
    } > "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
}

write_generated_state

expect_processed "missing Blueprint keeps all Homebrew packages eligible" \
    "selected-package unselected-package" install_brew_packages
expect_processed "missing Blueprint keeps all Homebrew casks eligible" \
    "selected-cask unselected-cask" install_brew_casks
expect_processed "missing Blueprint keeps all App Store IDs eligible" \
    "111 222" install_appstore_apps
expect_processed "missing Blueprint keeps all VS Code extensions eligible" \
    "selected.extension unselected.extension" install_vscode_extensions
bootstrap_workspace_folders >/dev/null
if [[ -d "$HOME/SelectedFolder" && -d "$HOME/UnselectedFolder" ]]; then
    pass "missing Blueprint keeps all workspace folders eligible"
else
    fail "missing Blueprint did not keep all workspace folders eligible"
fi
expect_processed "missing Blueprint keeps all repositories eligible" \
    "selected-repository unselected-repository" bootstrap_workspace_repositories

rm -rf "$HOME/SelectedFolder" "$HOME/UnselectedFolder"
write_blueprint

expect_processed "Blueprint filters Homebrew packages" \
    "selected-package" install_brew_packages
expect_processed "Blueprint filters Homebrew casks" \
    "selected-cask" install_brew_casks
expect_processed "Blueprint filters App Store applications by ID" \
    "111" install_appstore_apps
expect_processed "Blueprint filters VS Code extensions" \
    "selected.extension" install_vscode_extensions
bootstrap_workspace_folders >/dev/null
if [[ -d "$HOME/SelectedFolder" && ! -d "$HOME/UnselectedFolder" ]]; then
    pass "Blueprint filters workspace folders"
else
    fail "Blueprint workspace folder filtering failed"
fi
expect_processed "Blueprint filters repositories by identifier" \
    "selected-repository" bootstrap_workspace_repositories

rm -rf "$HOME/SelectedFolder" "$HOME/UnselectedFolder"
write_blueprint false

expect_processed "empty Homebrew package section processes zero items" \
    "" install_brew_packages
expect_processed "empty Homebrew cask section processes zero items" \
    "" install_brew_casks
expect_processed "empty App Store section processes zero items" \
    "" install_appstore_apps
expect_processed "empty VS Code extension section processes zero items" \
    "" install_vscode_extensions
bootstrap_workspace_folders >/dev/null
if [[ ! -d "$HOME/SelectedFolder" && ! -d "$HOME/UnselectedFolder" ]]; then
    pass "empty workspace folder section processes zero items"
else
    fail "empty workspace folder section processed items"
fi
expect_processed "empty repository section processes zero items" \
    "" bootstrap_workspace_repositories

write_blueprint
echo '[malformed' >> "$BLUEPRINT_FILE"
expect_status "malformed Blueprint prevents filtered operations" 2 \
    blueprint_validate "$BLUEPRINT_FILE"

write_blueprint
sed -i.bak 's/selected-package/stale-package/' "$BLUEPRINT_FILE"
rm -f "$BLUEPRINT_FILE.bak"
expect_status "stale selection preserves warning status" 1 \
    blueprint_validate "$BLUEPRINT_FILE"

write_blueprint
{
    echo
    echo '[selected-repository]'
    echo 'PATH="/duplicate"'
} >> "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
expect_status "repository collision remains an error" 2 \
    blueprint_validate "$BLUEPRINT_FILE"

install_brew_packages() {
    record_orchestration_step homebrew-packages
}

install_brew_casks() {
    record_orchestration_step homebrew-casks
}

install_appstore_apps() {
    record_orchestration_step app-store
}

install_vscode_extensions() {
    record_orchestration_step vscode-extensions
}

write_generated_state
write_blueprint
echo '[malformed' >> "$BLUEPRINT_FILE"
reset_orchestration
run_bootstrap_orchestration >/dev/null
toolkit_exit_code
orchestration_status=$?

if [[ $ERROR_COUNT -eq 1 && $WARNING_COUNT -eq 0 &&
      $orchestration_status -eq 2 && -z "$PROCESSED_ITEMS" ]]; then
    pass "malformed Blueprint records error and blocks Bootstrap orchestration"
else
    fail "malformed Blueprint orchestration (errors=$ERROR_COUNT, warnings=$WARNING_COUNT, status=$orchestration_status, processed='$PROCESSED_ITEMS')"
fi

write_blueprint
sed -i.bak 's/selected-package/stale-package/' "$BLUEPRINT_FILE"
rm -f "$BLUEPRINT_FILE.bak"
reset_orchestration
run_bootstrap_orchestration >/dev/null
toolkit_exit_code
orchestration_status=$?
expected_steps="workspace git-configuration homebrew-packages homebrew-casks app-store vscode-extensions vscode-settings macos-settings"

if [[ $WARNING_COUNT -eq 1 && $ERROR_COUNT -eq 0 &&
      $orchestration_status -eq 1 && "$PROCESSED_ITEMS" == "$expected_steps" ]]; then
    pass "stale Blueprint warning survives successful Bootstrap orchestration"
else
    fail "stale Blueprint orchestration (errors=$ERROR_COUNT, warnings=$WARNING_COUNT, status=$orchestration_status, processed='$PROCESSED_ITEMS')"
fi

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo
    echo "$TEST_FAILURES Blueprint Bootstrap filtering test(s) failed"
    exit 1
fi

echo
echo "All Blueprint Bootstrap filtering tests passed"
