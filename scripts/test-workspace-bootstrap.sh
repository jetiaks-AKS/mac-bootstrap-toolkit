#!/bin/bash

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'chmod -R u+rwX "$TEST_ROOT" 2>/dev/null; rm -rf "$TEST_ROOT"' EXIT INT TERM

cd "$PROJECT_ROOT" || exit 1

HOME="$TEST_ROOT/home"
BLUEPRINT_GENERATED_DIR="$TEST_ROOT/generated"
VERBOSE=false
BLUEPRINT_PRESENT=false
SELECTED_FOLDERS=""
SELECTED_REPOSITORIES=""
MUTATION_LOG="$TEST_ROOT/mutations.log"
TEST_FAILURES=0

mkdir -p "$HOME" "$BLUEPRINT_GENERATED_DIR/workspace"
: > "$MUTATION_LOG"

source modules/core/common/common.sh
source modules/core/config/config.sh
source modules/blueprint/blueprint.sh
source modules/discovery/workspace.sh
source modules/bootstrap/workspace/workspace.sh

log() { :; }
section() { :; }
detail() { :; }
info() { :; }
action() { :; }
success() { printf 'SUCCESS:%s\n' "$*"; }
warning() { printf 'WARNING:%s\n' "$*"; }
error() { printf 'ERROR:%s\n' "$*"; }

blueprint_exists() { [[ "$BLUEPRINT_PRESENT" == true ]]; }
blueprint_selected_items() {
    case "$1" in
        workspace-folders) printf '%s\n' "$SELECTED_FOLDERS" ;;
        git-repositories) printf '%s\n' "$SELECTED_REPOSITORIES" ;;
    esac
}
blueprint_item_selected() {
    [[ "$BLUEPRINT_PRESENT" != true ]] && return 0
    case "$1" in
        workspace-folders) grep -Fxq -- "$2" <<< "$SELECTED_FOLDERS" ;;
        git-repositories) grep -Fxq -- "$2" <<< "$SELECTED_REPOSITORIES" ;;
    esac
}
blueprint_generated_file() {
    case "$1" in
        workspace-folders) printf '%s\n' "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf" ;;
        git-repositories) printf '%s\n' "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf" ;;
        *) return 1 ;;
    esac
}

repository_clone() {
    printf 'clone:%s:%s\n' "$1" "$2" >> "$MUTATION_LOG"
    return 0
}
repository_checkout() {
    printf 'checkout:%s:%s\n' "$1" "$2" >> "$MUTATION_LOG"
    return 0
}
repository_verify() {
    repository_clone "$2" "$1"
}
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; ((TEST_FAILURES++)); }
expect_status() {
    local expected="$1"
    local actual="$2"
    local label="$3"
    [[ "$actual" -eq "$expected" ]] && pass "$label" || fail "$label (expected $expected, got $actual)"
}
assert_no_mutation() {
    local label="$1"
    if [[ ! -s "$MUTATION_LOG" && ! -d "$HOME/Projects" && ! -d "$HOME/Other" ]]; then
        pass "$label"
    else
        fail "$label"
    fi
}
reset_case() {
    chmod -R u+rwX "$BLUEPRINT_GENERATED_DIR" 2>/dev/null || true
    rm -rf "$HOME/Projects" "$HOME/Other" "$BLUEPRINT_GENERATED_DIR/workspace"
    mkdir -p "$BLUEPRINT_GENERATED_DIR/workspace"
    : > "$MUTATION_LOG"
    BLUEPRINT_PRESENT=false
    SELECTED_FOLDERS=""
    SELECTED_REPOSITORIES=""
    MODULE_CHANGED=false
}
write_valid_folders() {
    printf 'Projects|workspace\nOther|user\n' > \
        "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"
}
write_repository_section() {
    local identifier="$1"
    local path="$2"
    cat <<EOF
[$identifier]
NAME="$identifier"
PATH="$path"
REMOTE="git@example.com:$identifier.git"
DEFAULT_BRANCH="main"
CURRENT_BRANCH="main"
HAS_UNCOMMITTED_CHANGES="false"
HAS_VSCODE_FOLDER="false"
HAS_SETTINGS="false"
HAS_TASKS="false"
HAS_LAUNCH="false"
HAS_EXTENSIONS="false"
EOF
}
write_valid_repositories() {
    {
        write_repository_section selected-repository "$HOME/Projects/selected-repository"
        echo
        write_repository_section other-repository "$HOME/Other/other-repository"
    } > "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
}

# Valid no-Blueprint input retains all-inclusive behavior.
reset_case
write_valid_folders
write_valid_repositories
output="$(bootstrap_workspace)"; status=$?
expect_status 0 "$status" "valid Workspace generated state continues to work"
if [[ "$output" != *'Restoring VS Code workspace'* &&
      "$output" != *'VS Code workspace restored'* ]]; then
    pass "Workspace Bootstrap emits no false VS Code workspace restoration"
else
    fail "Workspace Bootstrap emitted false VS Code workspace restoration"
fi
if [[ -d "$HOME/Projects" && -d "$HOME/Other" &&
      "$(grep -c '^clone:' "$MUTATION_LOG")" -eq 2 ]]; then
    pass "no-Blueprint Workspace behavior remains all-inclusive"
else
    fail "no-Blueprint Workspace behavior changed"
fi

# Complete folder validation occurs before mkdir.
reset_case
printf 'Projects|invalid\n' > "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"
write_valid_repositories
output="$(bootstrap_workspace 2>&1)"; status=$?
expect_status 2 "$status" "malformed folder record returns 2"
assert_no_mutation "malformed folder input causes zero Workspace mutations"
[[ "$output" != *'SUCCESS:Workspace Bootstrap completed'* ]] || fail "malformed folders emitted false Workspace success"
pass "malformed folder input emits no Workspace completion success"

reset_case
write_valid_repositories
output="$(bootstrap_workspace 2>&1)"; status=$?
expect_status 2 "$status" "missing required folder input returns 2"
assert_no_mutation "missing folder input fails before mutation"

reset_case
write_valid_folders
write_valid_repositories
chmod 000 "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"
output="$(bootstrap_workspace 2>&1)"; status=$?
chmod 600 "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"
expect_status 2 "$status" "unreadable required folder input returns 2"
assert_no_mutation "unreadable folder input fails before mutation"

# Complete repository validation occurs before earlier folder creation.
reset_case
write_valid_folders
printf '[broken]\nPATH="%s"\n' "$HOME/Projects/broken" > \
    "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
output="$(bootstrap_workspace 2>&1)"; status=$?
expect_status 2 "$status" "malformed repository record returns 2"
assert_no_mutation "malformed repository input blocks mkdir, clone, and checkout"
[[ "$output" != *'SUCCESS:Workspace Bootstrap completed'* ]] || fail "malformed repositories emitted false Workspace success"
pass "malformed repository input emits no Workspace completion success"

reset_case
write_valid_folders
write_valid_repositories
sed 's/HAS_SETTINGS="false"/HAS_SETTINGS="invalid"/' \
    "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf" > "$TEST_ROOT/repositories.invalid"
mv "$TEST_ROOT/repositories.invalid" "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
bootstrap_workspace >/dev/null 2>&1; status=$?
expect_status 2 "$status" "invalid repository boolean is rejected"
assert_no_mutation "invalid repository boolean causes zero Workspace mutations"

reset_case
write_valid_folders
{
    write_repository_section duplicate "$HOME/Projects/one"
    echo
    write_repository_section duplicate "$HOME/Projects/two"
} > "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
bootstrap_workspace >/dev/null 2>&1; status=$?
expect_status 2 "$status" "duplicate repository identifier is rejected"
assert_no_mutation "duplicate repository identifier causes zero Workspace mutations"

reset_case
write_valid_folders
bootstrap_workspace >/dev/null 2>&1; status=$?
expect_status 2 "$status" "missing required repository input returns 2"
assert_no_mutation "missing repository input fails before folder mutation"

reset_case
write_valid_folders
write_valid_repositories
chmod 000 "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
bootstrap_workspace >/dev/null 2>&1; status=$?
chmod 600 "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
expect_status 2 "$status" "unreadable required repository input returns 2"
assert_no_mutation "unreadable repository input fails before folder mutation"

# Blueprint selections determine which inputs are required, not how they are parsed.
reset_case
write_valid_folders
write_valid_repositories
BLUEPRINT_PRESENT=true
SELECTED_FOLDERS="Projects"
SELECTED_REPOSITORIES="selected-repository"
bootstrap_workspace >/dev/null 2>&1; status=$?
expect_status 0 "$status" "valid selected Workspace entries continue to work"
if [[ -d "$HOME/Projects" && ! -d "$HOME/Other" &&
      "$(grep -c '^clone:' "$MUTATION_LOG")" -eq 1 &&
      "$(cat "$MUTATION_LOG")" == *selected-repository* ]]; then
    pass "Blueprint Workspace filtering remains unchanged"
else
    fail "Blueprint Workspace filtering changed"
fi

reset_case
BLUEPRINT_PRESENT=true
bootstrap_workspace >/dev/null 2>&1; status=$?
expect_status 0 "$status" "empty Blueprint Workspace selections preserve skip behavior"
assert_no_mutation "empty Blueprint Workspace selections do not validate or mutate"

# Existing run_module lifecycle records validation error 2 permanently.
reset_case
write_valid_folders
printf '[broken]\n' > "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
WARNING_COUNT=0
ERROR_COUNT=0
MODULES_CHECKED=0
run_module "Workspace" bootstrap_workspace >/dev/null 2>&1; status=$?
expect_status 2 "$status" "Workspace validation failure reaches run_module"
[[ "$ERROR_COUNT" -eq 1 ]] && pass "run_module records Workspace validation error" || fail "run_module lost Workspace validation error"
later_success() { return 0; }
run_module "Later Success" later_success >/dev/null 2>&1
toolkit_exit_code; status=$?
expect_status 2 "$status" "later success cannot erase Workspace validation error"
assert_no_mutation "Workspace lifecycle failure performs zero mutations"

echo
if [[ $TEST_FAILURES -eq 0 ]]; then
    echo "All Workspace Bootstrap validation tests passed"
    exit 0
fi

echo "$TEST_FAILURES Workspace Bootstrap validation test(s) failed" >&2
exit 1
