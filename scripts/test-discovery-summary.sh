#!/bin/bash

# Focused Summary coverage; no real Discovery or system mutations.
set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM
TEST_FAILURES=0
VERBOSE=false

source "$PROJECT_ROOT/modules/core/common/common.sh"
source "$PROJECT_ROOT/modules/core/logger/logger.sh"
source "$PROJECT_ROOT/modules/discovery/discovery.sh"

LOG_FILE="$TEST_ROOT/summary.log"
START_TIME=""

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; ((TEST_FAILURES++)); }

module_success() { return 0; }
module_changed() { MODULE_CHANGED=true; return 0; }
discover_homebrew() { return "$DISCOVERY_STATUS"; }
discover_appstore() { return 0; }
discover_git() { return 0; }
discover_vscode() { return 0; }
discover_macos() { return 0; }
discover_workspace() { return 0; }

verify_summary() {
    local label="$1"
    local expected_status="$2"
    local headline="$3"
    local before="$MODULES_CHECKED/$INSTALLED_COUNT/$SKIPPED_COUNT/$WARNING_COUNT/$ERROR_COUNT/$MODULE_CHANGED"
    local result
    local output

    : > "$LOG_FILE"
    # Run directly so counter mutations cannot hide in a subshell.
    show_summary > "$TEST_ROOT/terminal"
    toolkit_exit_code
    result=$?
    output="$(cat "$TEST_ROOT/terminal")"
    sed 's/^[^ ]* [^ ]* //' "$LOG_FILE" > "$TEST_ROOT/log-body"

    if [[ "$before" == "$MODULES_CHECKED/$INSTALLED_COUNT/$SKIPPED_COUNT/$WARNING_COUNT/$ERROR_COUNT/$MODULE_CHANGED" &&
          $result -eq $expected_status && "$output" == *"$headline"* ]] &&
       cmp -s "$TEST_ROOT/terminal" "$TEST_ROOT/log-body"; then
        pass "$label: headline, exit status, state preservation, terminal/log parity"
    else
        fail "$label: lifecycle or logging regression"
    fi

    if [[ "$MODE" == "--discover" ]]; then
        if [[ "$output" == *"Modules Processed : $MODULES_CHECKED"* &&
              "$output" == *"Warnings          : $WARNING_COUNT"* &&
              "$output" == *"Errors            : $ERROR_COUNT"* &&
              "$output" != *Installed* && "$output" != *Skipped* &&
              "$output" != *"Modules Checked"* ]]; then
            pass "$label: Discovery fields"
        else
            fail "$label: misleading Discovery fields"
        fi
    elif [[ "$MODE" == "--dry-run" ]]; then
        if [[ "$output" == *"Modules Inspected : $MODULES_CHECKED"* &&
              "$output" == *"Warnings          : $WARNING_COUNT"* &&
              "$output" == *"Errors            : $ERROR_COUNT"* &&
              "$output" != *Installed* && "$output" != *Skipped* &&
              "$output" != *"Modules Checked"* ]]; then
            pass "$label: Preview fields"
        else
            fail "$label: misleading Preview fields"
        fi
    else
        if [[ "$output" == *"Modules Checked : $MODULES_CHECKED"* &&
              "$output" == *"Installed       : $INSTALLED_COUNT"* &&
              "$output" == *"Skipped         : $SKIPPED_COUNT"* &&
              "$output" == *"Warnings        : $WARNING_COUNT"* &&
              "$output" == *"Errors          : $ERROR_COUNT"* &&
              "$output" != *"Modules Processed"* ]]; then
            pass "$label: legacy fields"
        else
            fail "$label: changed legacy fields"
        fi
    fi
}

MODE=--discover
for DISCOVERY_STATUS in 0 1 2; do
    MODULES_CHECKED=0
    INSTALLED_COUNT=0
    SKIPPED_COUNT=0
    WARNING_COUNT=0
    ERROR_COUNT=0
    # Four shared Core calls followed by the real six-module controller.
    run_module Core module_changed >/dev/null
    for core_module in Git SSH Terminal; do
        run_module "$core_module" module_success >/dev/null
    done
    run_discovery >/dev/null
    [[ $MODULES_CHECKED -eq 10 && $INSTALLED_COUNT -eq 1 && $SKIPPED_COUNT -eq 9 ]] ||
        fail "controller accounting changed"
    [[ $WARNING_COUNT -eq $((DISCOVERY_STATUS == 1 ? 1 : 0)) &&
       $ERROR_COUNT -eq $((DISCOVERY_STATUS == 2 ? 1 : 0)) ]] ||
        fail "controller warning/error accounting changed"
    case "$DISCOVERY_STATUS" in
        0) headline='[ OK ] Discovery completed successfully' ;;
        1) headline='[WARN] Discovery completed with warnings' ;;
        2) headline='[ERROR] Discovery completed with errors' ;;
    esac
    verify_summary "Discovery status $DISCOVERY_STATUS" "$DISCOVERY_STATUS" "$headline"
done

WARNING_COUNT=2
verify_summary 'Discovery mixed results' 2 '[ERROR] Discovery completed with errors'

MODULES_CHECKED=0
INSTALLED_COUNT=0
SKIPPED_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=1
verify_summary 'Discovery preflight failure' 2 '[ERROR] Discovery completed with errors'

START_TIME="$(date +%s)"
verify_summary 'Discovery duration' 2 '[ERROR] Discovery completed with errors'
grep -q '^Duration        : [0-9][0-9]*s$' "$TEST_ROOT/terminal" || fail 'duration missing'
START_TIME=""

BLUEPRINT_BOOTSTRAP_SUMMARY=false
MODULES_CHECKED=4
INSTALLED_COUNT=1
SKIPPED_COUNT=3
for MODE in --check --bootstrap; do
    case "$MODE" in
        --check) mode_name='System check' ;;
        --bootstrap) mode_name=Bootstrap ;;
    esac
    WARNING_COUNT=0
    ERROR_COUNT=0
    verify_summary "$MODE success" 0 "[ OK ] $mode_name completed successfully"
    WARNING_COUNT=1
    verify_summary "$MODE warning" 1 "[WARN] $mode_name completed with warnings"
    ERROR_COUNT=1
    verify_summary "$MODE error" 2 "[ERROR] $mode_name completed with errors"
done

MODE=--dry-run
MODULES_CHECKED=4
INSTALLED_COUNT=0
SKIPPED_COUNT=4
WARNING_COUNT=0
ERROR_COUNT=0
verify_summary 'Preview success' 0 '[ OK ] Preview completed successfully'
WARNING_COUNT=1
verify_summary 'Preview warning' 1 '[WARN] Preview completed with warnings'
ERROR_COUNT=1
verify_summary 'Preview error' 2 '[ERROR] Preview completed with errors'

if [[ $TEST_FAILURES -gt 0 ]]; then
    echo "$TEST_FAILURES failure(s)"
    exit 1
fi

echo 'All Summary checks passed'
