#!/bin/bash

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

VERBOSE=false
TEST_FAILURES=0

source "$PROJECT_ROOT/modules/core/common/common.sh"

log() { :; }
section() { :; }
success() { printf 'SUCCESS:%s\n' "$*"; }
error() { printf 'ERROR:%s\n' "$*"; }

CHECK_SEQUENCE=()
CHECK_INDEX=0
CHECK_CALLS=0
APPLY_STATUS=0
APPLY_CALLS=0
APPLY_SETS_CHANGED=false

lifecycle_check() {
    local status="${CHECK_SEQUENCE[$CHECK_INDEX]}"
    ((CHECK_INDEX++))
    ((CHECK_CALLS++))
    return "$status"
}

lifecycle_apply() {
    ((APPLY_CALLS++))
    [[ "$APPLY_SETS_CHANGED" != true ]] || MODULE_CHANGED=true
    return "$APPLY_STATUS"
}

pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; ((TEST_FAILURES++)); }

expect_status() {
    [[ "$1" -eq "$2" ]] && pass "$3" || fail "$3 (expected $1, got $2)"
}

reset_case() {
    MODULES_CHECKED=0
    INSTALLED_COUNT=0
    SKIPPED_COUNT=0
    WARNING_COUNT=0
    ERROR_COUNT=0
    MODULE_CHANGED=false
    CHECK_SEQUENCE=()
    CHECK_INDEX=0
    CHECK_CALLS=0
    APPLY_STATUS=0
    APPLY_CALLS=0
    APPLY_SETS_CHANGED=false
}

run_case() {
    run_configuration "Lifecycle Test" lifecycle_check lifecycle_apply > "$TEST_ROOT/output" 2>&1
    status=$?
    output="$(cat "$TEST_ROOT/output")"
}

reset_case
CHECK_SEQUENCE=(0)
run_case
expect_status 0 "$status" "Check 0 returns success"
[[ $APPLY_CALLS -eq 0 && $CHECK_CALLS -eq 1 && "$MODULE_CHANGED" == false &&
   $SKIPPED_COUNT -eq 1 && $ERROR_COUNT -eq 0 ]] || fail "Check 0 changed lifecycle state"

reset_case
CHECK_SEQUENCE=(1 0)
APPLY_SETS_CHANGED=true
run_case
expect_status 0 "$status" "Check 1 applies and Verify 0 succeeds"
[[ $APPLY_CALLS -eq 1 && $CHECK_CALLS -eq 2 && "$MODULE_CHANGED" == true &&
   $INSTALLED_COUNT -eq 1 && $ERROR_COUNT -eq 0 ]] || fail "successful lifecycle accounting changed"

reset_case
CHECK_SEQUENCE=(2)
run_case
expect_status 2 "$status" "Check 2 returns error"
[[ $APPLY_CALLS -eq 0 && $CHECK_CALLS -eq 1 && $ERROR_COUNT -eq 1 ]] ||
    fail "Check 2 reached Apply"

reset_case
CHECK_SEQUENCE=(1 0)
APPLY_STATUS=2
run_case
expect_status 2 "$status" "Apply failure returns error immediately"
[[ $APPLY_CALLS -eq 1 && $CHECK_CALLS -eq 1 && "$MODULE_CHANGED" == false &&
   $ERROR_COUNT -eq 1 && "$output" != *'configured successfully'* ]] ||
    fail "Apply failure was rechecked or reported as success"

reset_case
CHECK_SEQUENCE=(1 1)
APPLY_SETS_CHANGED=true
run_case
expect_status 2 "$status" "Verify mismatch returns error"
[[ $APPLY_CALLS -eq 1 && $CHECK_CALLS -eq 2 && "$MODULE_CHANGED" == true &&
   $INSTALLED_COUNT -eq 1 && $ERROR_COUNT -eq 1 ]] || fail "Verify mismatch accounting changed"

reset_case
CHECK_SEQUENCE=(1 2)
APPLY_SETS_CHANGED=true
run_case
expect_status 2 "$status" "Verify observation error returns error"
[[ $APPLY_CALLS -eq 1 && $CHECK_CALLS -eq 2 && "$MODULE_CHANGED" == true &&
   $INSTALLED_COUNT -eq 1 && $ERROR_COUNT -eq 1 ]] || fail "Verify error accounting changed"

reset_case
CHECK_SEQUENCE=(1 0)
run_case
expect_status 0 "$status" "consumer can report successful no-change Apply"
[[ "$MODULE_CHANGED" == false && $SKIPPED_COUNT -eq 1 && $INSTALLED_COUNT -eq 0 ]] ||
    fail "wrapper overwrote consumer MODULE_CHANGED state"

reset_case
CHECK_SEQUENCE=(1 0)
APPLY_STATUS=2
APPLY_SETS_CHANGED=true
run_case
expect_status 2 "$status" "failed Apply preserves retained consumer change"
[[ "$MODULE_CHANGED" == true && $INSTALLED_COUNT -eq 1 && $ERROR_COUNT -eq 1 ]] ||
    fail "failed Apply lost consumer MODULE_CHANGED state"

echo
if [[ $TEST_FAILURES -eq 0 ]]; then
    echo "All Core lifecycle tests passed"
    exit 0
fi

echo "$TEST_FAILURES Core lifecycle test(s) failed" >&2
exit 1
