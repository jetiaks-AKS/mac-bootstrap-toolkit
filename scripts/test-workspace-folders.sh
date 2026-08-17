#!/bin/bash

# ==========================================
# Workspace Folders Discovery Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

TEST_FAILURES=0
VERBOSE=false
SUCCESS_MESSAGES=""

action() { :; }
detail() { :; }
success() {
    SUCCESS_MESSAGES="${SUCCESS_MESSAGES}${SUCCESS_MESSAGES:+
}$1"
}

source "$PROJECT_ROOT/modules/discovery/workspace/folders.sh"

pass() { echo "PASS: $1"; }
fail() {
    echo "FAIL: $1"
    ((TEST_FAILURES++))
}

HOME="$TEST_ROOT/home"
mkdir -p "$HOME/Desktop" "$HOME/Library" "$HOME/CustomRoot" "$HOME/.hidden"
touch "$HOME/visible-file"

cd "$TEST_ROOT" || exit 1
LC_ALL=C export_workspace_folders >/dev/null

expected=$'CustomRoot|workspace\nDesktop|user\nLibrary|system'
actual="$(cat config/generated/workspace/folders.conf)"

if [[ "$actual" == "$expected" &&
      "$SUCCESS_MESSAGES" == *'3 folder(s) exported'* ]]; then
    pass "Discovery preserves broad visible-folder classification records"
else
    fail "Discovery enumeration, classification, format, or count changed"
fi

if [[ "$(classify_folder GitHUB)" == workspace &&
      "$(classify_folder Screenshots)" == workspace &&
      "$(classify_folder Documents)" == user &&
      "$(classify_folder Public)" == system ]]; then
    pass "classification remains name-derived rather than candidate-hard-coded"
else
    fail "Workspace folder classification rules changed"
fi

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo
    echo "$TEST_FAILURES Workspace folder test(s) failed"
    exit 1
fi

echo
echo "All Workspace folder tests passed"
