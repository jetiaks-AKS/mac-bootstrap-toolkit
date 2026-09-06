#!/bin/bash

# ==========================================
# Homebrew Availability Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_FAILURES=0
AVAILABILITY_SEQUENCE=()
AVAILABILITY_INDEX=0
INSTALL_CALLS=0
READ_CALLS=0

source "$PROJECT_ROOT/modules/core/homebrew/homebrew.sh"

info() { :; }
success() { :; }
warning() { :; }
error() { :; }

command() {
    if [[ "$1" == -v && "$2" == brew ]]; then
        local status="${AVAILABILITY_SEQUENCE[$AVAILABILITY_INDEX]}"
        ((AVAILABILITY_INDEX++))
        return "$status"
    fi
    builtin command "$@"
}

read() {
    ((READ_CALLS++))
    answer=y
}

install_homebrew() {
    ((INSTALL_CALLS++))
    return 0
}

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; ((TEST_FAILURES++)); }

reset_case() {
    AVAILABILITY_SEQUENCE=()
    AVAILABILITY_INDEX=0
    INSTALL_CALLS=0
    READ_CALLS=0
}

reset_case
AVAILABILITY_SEQUENCE=(2)
check_homebrew >/dev/null
status=$?
if [[ $status -eq 2 && $READ_CALLS -eq 0 && $INSTALL_CALLS -eq 0 ]]; then
    pass "availability observation error blocks installer"
else
    fail "availability error reached installer (status=$status, read=$READ_CALLS, install=$INSTALL_CALLS)"
fi

reset_case
AVAILABILITY_SEQUENCE=(1 0)
check_homebrew >/dev/null
status=$?
if [[ $status -eq 0 && $READ_CALLS -eq 1 && $INSTALL_CALLS -eq 1 ]]; then
    pass "absent Homebrew keeps normal install policy"
else
    fail "absent Homebrew policy changed (status=$status, read=$READ_CALLS, install=$INSTALL_CALLS)"
fi

reset_case
AVAILABILITY_SEQUENCE=(0)
check_homebrew >/dev/null
status=$?
if [[ $status -eq 0 && $READ_CALLS -eq 0 && $INSTALL_CALLS -eq 0 ]]; then
    pass "present Homebrew remains a no-op"
else
    fail "present Homebrew changed behavior (status=$status, read=$READ_CALLS, install=$INSTALL_CALLS)"
fi

for expected_status in 0 1 2; do
    reset_case
    AVAILABILITY_SEQUENCE=("$expected_status")
    check_homebrew_read_only >/dev/null
    status=$?
    if [[ $status -eq $expected_status && $READ_CALLS -eq 0 && $INSTALL_CALLS -eq 0 ]]; then
        pass "read-only Homebrew status $expected_status performs no installer action"
    else
        fail "read-only Homebrew status $expected_status mutated or returned $status"
    fi
done

if [[ $TEST_FAILURES -eq 0 ]]; then
    echo "All Homebrew availability tests passed"
    exit 0
fi

echo "$TEST_FAILURES Homebrew availability test(s) failed" >&2
exit 1
