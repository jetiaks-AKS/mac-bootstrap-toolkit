#!/bin/bash

# ==========================================
# Git and VS Code Settings Preview Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
REAL_GIT="$(command -v git)"
TEST_FAILURES=0
ACTION_MESSAGES=""
WARNING_MESSAGES=""
ERROR_MESSAGES=""
GIT_READ_FAILURE_KEY=""
CMP_FAILURE=false
MUTATION_LOG="$TEST_ROOT/mutations.log"

trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

export HOME="$TEST_ROOT/home"
export GIT_CONFIG_GLOBAL="$TEST_ROOT/global.gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export TMPDIR="$TEST_ROOT/tmp"

/bin/mkdir -p "$HOME" "$TMPDIR"
: > "$MUTATION_LOG"

action() {
    ACTION_MESSAGES="${ACTION_MESSAGES}${ACTION_MESSAGES:+
}$1"
}
warning() {
    WARNING_MESSAGES="${WARNING_MESSAGES}${WARNING_MESSAGES:+
}$1"
}
error() {
    ERROR_MESSAGES="${ERROR_MESSAGES}${ERROR_MESSAGES:+
}$1"
}
success() { :; }
detail() { :; }

git() {
    if [[ -n "$GIT_READ_FAILURE_KEY" &&
          "$*" == "config --global --null --get-all $GIT_READ_FAILURE_KEY" ]]; then
        return 2
    fi

    if [[ "${1:-}" == config && "${2:-}" == --global &&
          "${3:-}" != --null ]]; then
        printf '%s\n' "git $*" >> "$MUTATION_LOG"
    fi

    "$REAL_GIT" "$@"
}

cmp() {
    [[ "$CMP_FAILURE" == false ]] || return 2
    /usr/bin/cmp "$@"
}

mkdir() {
    printf '%s\n' "mkdir $*" >> "$MUTATION_LOG"
    return 2
}

cp() {
    printf '%s\n' "cp $*" >> "$MUTATION_LOG"
    return 2
}

mv() {
    printf '%s\n' "mv $*" >> "$MUTATION_LOG"
    return 2
}

source "$PROJECT_ROOT/modules/core/git/git.sh"
source "$PROJECT_ROOT/modules/vscode/settings.sh"

cd "$TEST_ROOT" || exit 1

pass() { echo "PASS: $1"; }
fail() {
    echo "FAIL: $1" >&2
    ((TEST_FAILURES++))
}

reset_messages() {
    ACTION_MESSAGES=""
    WARNING_MESSAGES=""
    ERROR_MESSAGES=""
    : > "$MUTATION_LOG"
}

reset_git_fixture() {
    /bin/rm -f "$GIT_CONFIG_GLOBAL"
    /bin/rm -rf "$TEST_ROOT/generated-git"
    /bin/mkdir -p "$TEST_ROOT/generated-git"
    GIT_CONFIGURATION_FILE="$TEST_ROOT/generated-git/git.conf"
    : > "$GIT_CONFIGURATION_FILE"
    GIT_READ_FAILURE_KEY=""
    reset_messages
}

write_generated_git() {
    "$REAL_GIT" config --file "$GIT_CONFIGURATION_FILE" "$1" "$2"
}

assert_no_mutation() {
    local label="$1"
    if [[ ! -s "$MUTATION_LOG" ]]; then
        pass "$label"
    else
        fail "$label: $(cat "$MUTATION_LOG")"
    fi
}

reset_git_fixture
write_generated_git user.name Current
"$REAL_GIT" config --global user.name Current
preview_git_configuration
if [[ $? -eq 0 && -z "$ACTION_MESSAGES" ]]; then
    pass "matching Git configuration has no planned action"
else
    fail "matching Git configuration produced a planned action"
fi
assert_no_mutation "matching Git Preview performs no write"

reset_git_fixture
write_generated_git user.name Desired
"$REAL_GIT" config --global user.name Current
preview_git_configuration
if [[ $? -eq 0 && "$ACTION_MESSAGES" == 'Would configure Git setting: user.name' ]]; then
    pass "one Git mismatch reports its planned setting"
else
    fail "one Git mismatch produced incorrect Preview output"
fi
assert_no_mutation "mismatched Git Preview performs no write"

reset_git_fixture
write_generated_git user.name Desired
write_generated_git user.email desired@example.com
preview_git_configuration
if [[ $? -eq 0 && "$ACTION_MESSAGES" == *'Would configure Git setting: user.name'* &&
      "$ACTION_MESSAGES" == *'Would configure Git setting: user.email'* ]]; then
    pass "multiple Git mismatches are all reported"
else
    fail "multiple Git mismatches were not all reported"
fi
first_preview="$ACTION_MESSAGES"
reset_messages
preview_git_configuration
if [[ $? -eq 0 && "$ACTION_MESSAGES" == "$first_preview" ]]; then
    pass "repeated Git Preview is stable"
else
    fail "repeated Git Preview output changed"
fi
assert_no_mutation "repeated Git Preview performs no write"

reset_git_fixture
write_generated_git user.name Desired
GIT_READ_FAILURE_KEY=core.editor
preview_git_configuration
if [[ $? -eq 2 && -z "$ACTION_MESSAGES" ]]; then
    pass "late Git observation error overrides earlier mismatch"
else
    fail "Git Preview hid a late observation error"
fi
assert_no_mutation "Git observation error performs no write"

reset_vscode_fixture() {
    VSCODE_SETTINGS_SOURCE_FILE="config/generated/vscode/settings.json"
    VSCODE_SETTINGS_TARGET_DIR="$HOME/Library/Application Support/Code/User"
    VSCODE_SETTINGS_TARGET_FILE="$VSCODE_SETTINGS_TARGET_DIR/settings.json"
    /bin/rm -rf config "$HOME/Library"
    /bin/mkdir -p config/generated/vscode "$VSCODE_SETTINGS_TARGET_DIR"
    printf '%s\n' '{"editor.fontSize": 14}' > "$VSCODE_SETTINGS_SOURCE_FILE"
    CMP_FAILURE=false
    MODULE_CHANGED=preserved
    reset_messages
}

reset_vscode_fixture
/bin/cp "$VSCODE_SETTINGS_SOURCE_FILE" "$VSCODE_SETTINGS_TARGET_FILE"
preview_vscode_settings
if [[ $? -eq 0 && -z "$ACTION_MESSAGES" && "$MODULE_CHANGED" == preserved ]]; then
    pass "equal VS Code settings have no planned action or Changed state"
else
    fail "equal VS Code settings Preview changed lifecycle state"
fi
assert_no_mutation "equal VS Code settings Preview performs no mutation"

reset_vscode_fixture
/bin/rm -f "$VSCODE_SETTINGS_TARGET_FILE"
preview_vscode_settings
if [[ $? -eq 0 && "$ACTION_MESSAGES" == 'Would update VS Code settings' ]]; then
    pass "absent VS Code settings report the update"
else
    fail "absent VS Code settings produced incorrect Preview output"
fi
assert_no_mutation "absent VS Code settings Preview performs no mutation"

reset_vscode_fixture
printf '%s\n' '{"editor.fontSize": 12}' > "$VSCODE_SETTINGS_TARGET_FILE"
preview_vscode_settings
first_preview="$ACTION_MESSAGES"
reset_messages
preview_vscode_settings
if [[ $? -eq 0 && "$ACTION_MESSAGES" == 'Would update VS Code settings' &&
      "$ACTION_MESSAGES" == "$first_preview" && "$MODULE_CHANGED" == preserved ]]; then
    pass "different VS Code settings Preview is stable"
else
    fail "different VS Code settings Preview is unstable"
fi
assert_no_mutation "different VS Code settings Preview performs no mutation"

reset_vscode_fixture
/bin/rm -f "$VSCODE_SETTINGS_SOURCE_FILE"
preview_vscode_settings
if [[ $? -eq 1 && "$WARNING_MESSAGES" == *'not found'* && -z "$ACTION_MESSAGES" ]]; then
    pass "optional missing VS Code source preserves warning semantics"
else
    fail "optional missing VS Code source changed semantics"
fi
assert_no_mutation "missing VS Code source performs no mutation"

reset_vscode_fixture
printf '%s\n' '{"editor.fontSize": 12}' > "$VSCODE_SETTINGS_TARGET_FILE"
CMP_FAILURE=true
preview_vscode_settings
if [[ $? -eq 2 && "$ERROR_MESSAGES" == *'Failed to inspect VS Code Settings'* &&
      -z "$ACTION_MESSAGES" ]]; then
    pass "VS Code comparison error returns 2 without a plan"
else
    fail "VS Code comparison error was treated as a planned update"
fi
assert_no_mutation "VS Code comparison error performs no mutation"

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo "$TEST_FAILURES configuration Preview test(s) failed" >&2
    exit 1
fi

echo "All configuration Preview tests passed"
