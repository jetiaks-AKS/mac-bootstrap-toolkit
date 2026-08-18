#!/bin/bash

# ==========================================
# Blueprint Test Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

BLUEPRINT_FILE="$TEST_ROOT/blueprint.conf"
BLUEPRINT_GENERATED_DIR="$TEST_ROOT/generated"

WARNING_MESSAGES=""
ERROR_MESSAGES=""
SUCCESS_MESSAGES=""
TEST_FAILURES=0

warning() {
    WARNING_MESSAGES="${WARNING_MESSAGES}${WARNING_MESSAGES:+
}$1"
}

error() {
    ERROR_MESSAGES="${ERROR_MESSAGES}${ERROR_MESSAGES:+
}$1"
}

success() {
    SUCCESS_MESSAGES="${SUCCESS_MESSAGES}${SUCCESS_MESSAGES:+
}$1"
}

source "$PROJECT_ROOT/modules/blueprint/blueprint.sh"

reset_messages() {
    WARNING_MESSAGES=""
    ERROR_MESSAGES=""
    SUCCESS_MESSAGES=""
}

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1"
    ((TEST_FAILURES++))
}

expect_status() {
    local label="$1"
    local expected="$2"

    shift 2
    reset_messages

    "$@" >/dev/null
    local actual=$?

    if [[ $actual -eq $expected ]]; then
        pass "$label -> $actual"
    else
        fail "$label (expected $expected, got $actual)"
    fi
}

expect_output() {
    local label="$1"
    local expected="$2"

    shift 2

    local actual
    actual="$("$@")"

    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label (expected '$expected', got '$actual')"
    fi
}

write_blueprint() {
    local file="$1"
    local git_enabled="${2-true}"
    local package="${3-git}"
    local repository="${4-project-a}"

    {
        echo '[categories]'
        echo "git-configuration=\"$git_enabled\""
        echo 'vscode-settings="false"'
        echo 'macos-finder="true"'
        echo 'macos-dock="true"'
        echo 'macos-keyboard="false"'
        echo 'macos-trackpad="false"'
        echo 'macos-screenshots="true"'
        echo
        echo '[homebrew-packages]'
        [[ -n "$package" ]] && echo "$package"
        echo
        echo '[homebrew-casks]'
        echo 'firefox'
        echo
        echo '[app-store]'
        echo '123456789'
        echo
        echo '[vscode-extensions]'
        echo 'publisher.extension-a'
        echo
        echo '[workspace-folders]'
        echo 'Projects'
        echo
        echo '[git-repositories]'
        [[ -n "$repository" ]] && echo "$repository"
    } > "$file"
}

write_generated_state() {
    mkdir -p "$BLUEPRINT_GENERATED_DIR/workspace"

    echo 'git' > "$BLUEPRINT_GENERATED_DIR/brew-packages.conf"
    echo 'firefox' > "$BLUEPRINT_GENERATED_DIR/brew-casks.conf"
    echo '123456789|Example Application' > "$BLUEPRINT_GENERATED_DIR/appstore.conf"
    echo 'publisher.extension-a' > "$BLUEPRINT_GENERATED_DIR/vscode-extensions.conf"
    {
        echo 'Desktop|user'
        echo 'Projects|workspace'
        echo 'Library|system'
        echo 'CustomRoot|workspace'
    } > "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"

    {
        echo '[project-a]'
        echo 'NAME="project-a"'
        echo 'PATH="/example/project-a"'
    } > "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
}

mkdir -p "$BLUEPRINT_GENERATED_DIR"
write_generated_state

expect_status "missing Blueprint" 0 blueprint_validate "$BLUEPRINT_FILE"
expect_status "missing Blueprint category uses legacy behavior" 0 \
    blueprint_category_enabled git-configuration "$BLUEPRINT_FILE"
expect_status "missing Blueprint item uses legacy behavior" 0 \
    blueprint_item_selected homebrew-packages anything "$BLUEPRINT_FILE"
expect_status "missing Blueprint keeps broad workspace folder behavior" 0 \
    blueprint_item_selected workspace-folders Desktop "$BLUEPRINT_FILE"

expect_output "workspace candidates use generated classification" \
    $'Projects\nCustomRoot' blueprint_workspace_folder_candidates
expect_status "workspace classification drives candidate eligibility" 0 \
    blueprint_workspace_folder_candidate CustomRoot
expect_status "folder name does not override non-workspace classification" 1 \
    blueprint_workspace_folder_candidate Desktop

write_blueprint "$BLUEPRINT_FILE"

expect_status "valid Blueprint" 0 blueprint_validate "$BLUEPRINT_FILE"
if [[ "$SUCCESS_MESSAGES" == "Blueprint configuration is valid" ]]; then
    pass "valid Blueprint reports success"
else
    fail "valid Blueprint success message missing or duplicated"
fi
expect_status "example syntax" 0 blueprint_validate_syntax \
    "$PROJECT_ROOT/config/blueprint.example.conf"
expect_status "selected item" 0 blueprint_item_selected \
    homebrew-packages git "$BLUEPRINT_FILE"
expect_status "unselected item" 1 blueprint_item_selected \
    homebrew-packages curl "$BLUEPRINT_FILE"
expect_status "category true" 0 blueprint_category_enabled \
    git-configuration "$BLUEPRINT_FILE"
expect_status "category false" 1 blueprint_category_enabled \
    vscode-settings "$BLUEPRINT_FILE"
expect_output "selected items" "git" blueprint_selected_items \
    homebrew-packages "$BLUEPRINT_FILE"
expect_status "selected workspace candidate remains active" 0 \
    blueprint_item_selected workspace-folders Projects "$BLUEPRINT_FILE"

awk '
    { print }
    $0 == "[workspace-folders]" { print "Desktop"; print "Library" }
' "$BLUEPRINT_FILE" > "$TEST_ROOT/legacy-workspace.conf"
reset_messages
blueprint_validate "$TEST_ROOT/legacy-workspace.conf" >/dev/null
legacy_validation_status=$?
if [[ $legacy_validation_status -eq 0 && -z "$WARNING_MESSAGES" ]]; then
    pass "observed legacy user/system selections are normalization, not stale"
else
    fail "legacy user/system selections produced incorrect validation semantics"
fi
expect_status "legacy user folder selection is inactive with Blueprint" 1 \
    blueprint_item_selected workspace-folders Desktop "$TEST_ROOT/legacy-workspace.conf"

awk '
    { print }
    $0 == "[workspace-folders]" { print "MissingWorkspace" }
' "$BLUEPRINT_FILE" > "$TEST_ROOT/stale-workspace.conf"
reset_messages
blueprint_validate "$TEST_ROOT/stale-workspace.conf" >/dev/null
stale_workspace_status=$?
if [[ $stale_workspace_status -eq 1 &&
      "$WARNING_MESSAGES" == *'Stale Blueprint item in workspace-folders: MissingWorkspace'* ]]; then
    pass "genuinely missing workspace selection remains stale"
else
    fail "genuinely stale workspace selection lost warning semantics"
fi

write_blueprint "$BLUEPRINT_FILE" true ""
expect_status "empty item section" 0 blueprint_validate "$BLUEPRINT_FILE"
expect_output "empty item section selects zero items" "" blueprint_selected_items \
    homebrew-packages "$BLUEPRINT_FILE"

write_blueprint "$BLUEPRINT_FILE"
echo '[malformed' >> "$BLUEPRINT_FILE"
expect_status "malformed section" 2 blueprint_validate "$BLUEPRINT_FILE"
if [[ -z "$SUCCESS_MESSAGES" ]]; then
    pass "malformed Blueprint does not report success"
else
    fail "malformed Blueprint reported false success"
fi

write_blueprint "$BLUEPRINT_FILE"
{
    echo
    echo '[unknown-section]'
} >> "$BLUEPRINT_FILE"
expect_status "unknown section" 2 blueprint_validate "$BLUEPRINT_FILE"

write_blueprint "$BLUEPRINT_FILE" yes
expect_status "invalid boolean" 2 blueprint_validate "$BLUEPRINT_FILE"

write_blueprint "$BLUEPRINT_FILE"
awk '
    { print }
    $0 == "git" { print }
' "$BLUEPRINT_FILE" > "$TEST_ROOT/duplicate.conf"
expect_status "duplicate item" 2 blueprint_validate "$TEST_ROOT/duplicate.conf"

write_blueprint "$BLUEPRINT_FILE"
awk '
    { print }
    $0 == "git" { print "git=\"true\"" }
' "$BLUEPRINT_FILE" > "$TEST_ROOT/item-assignment.conf"
expect_status "assignment syntax in item section" 2 \
    blueprint_validate "$TEST_ROOT/item-assignment.conf"

write_blueprint "$BLUEPRINT_FILE"
awk '
    $0 == "[git-repositories]" { skip = true; next }
    skip && $0 == "project-a" { next }
    { print }
' "$BLUEPRINT_FILE" > "$TEST_ROOT/missing-section.conf"
expect_status "missing mandatory section" 2 \
    blueprint_validate "$TEST_ROOT/missing-section.conf"

write_blueprint "$BLUEPRINT_FILE"
awk '
    { print }
    $0 == "git-configuration=\"true\"" { print }
' "$BLUEPRINT_FILE" > "$TEST_ROOT/duplicate-category.conf"
expect_status "duplicate category key" 2 \
    blueprint_validate "$TEST_ROOT/duplicate-category.conf"

write_blueprint "$BLUEPRINT_FILE" true stale-package
expect_status "stale selected item" 1 blueprint_validate "$BLUEPRINT_FILE"
if [[ -n "$WARNING_MESSAGES" && -z "$SUCCESS_MESSAGES" ]]; then
    pass "stale Blueprint preserves warning without clean success"
else
    fail "stale Blueprint warning or success messaging is incorrect"
fi

write_blueprint "$BLUEPRINT_FILE"
{
    echo
    echo '[project-a]'
    echo 'NAME="project-a"'
    echo 'PATH="/example/duplicate/project-a"'
} >> "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
expect_status "repository identifier collision" 2 blueprint_validate "$BLUEPRINT_FILE"

write_blueprint "$BLUEPRINT_FILE" true stale-package
expect_status "warning plus error preserves error" 2 blueprint_validate "$BLUEPRINT_FILE"

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo
    echo "$TEST_FAILURES Blueprint test(s) failed"
    exit 1
fi

echo
echo "All Blueprint tests passed"
