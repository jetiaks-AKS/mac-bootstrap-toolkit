#!/bin/bash

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM
cd "$PROJECT_ROOT" || exit 1

HOME="$TEST_ROOT/home"
STATE_FILE="$TEST_ROOT/defaults-state"
MUTATION_LOG="$TEST_ROOT/mutations"
OBSERVATION_LOG="$TEST_ROOT/observations"
VERBOSE=false
MODULE_CHANGED=false
ENABLED_CATEGORIES="all"
READ_TYPE_FAILURE=""
READ_FAILURE=""
WRITE_STATUS=0
POST_WRITE_MODE="match"
KILLALL_STATUS=0
MKDIR_STATUS=0
TEST_FAILURES=0

mkdir -p "$HOME" "$TEST_ROOT/generated/macos"
: > "$STATE_FILE"
: > "$MUTATION_LOG"
: > "$OBSERVATION_LOG"

source modules/core/common/common.sh
source modules/settings/macos/macos.sh

FINDER_CONFIG="$TEST_ROOT/generated/macos/finder.conf"
DOCK_CONFIG="$TEST_ROOT/generated/macos/dock.conf"
KEYBOARD_CONFIG="$TEST_ROOT/generated/macos/keyboard.conf"
TRACKPAD_CONFIG="$TEST_ROOT/generated/macos/trackpad.conf"
SCREENSHOTS_CONFIG="$TEST_ROOT/generated/macos/screenshots.conf"

log() { :; }
blueprint_category_enabled() {
    [[ "$ENABLED_CATEGORIES" == all ]] || grep -Fxq "$1" <<< "$ENABLED_CATEGORIES"
}
killall() {
    printf 'killall:%s\n' "$1" >> "$MUTATION_LOG"
    return "$KILLALL_STATUS"
}
mkdir() {
    local target="${!#}"
    if [[ "$target" == "$HOME/Screenshots" ]]; then
        printf 'mkdir:%s\n' "$target" >> "$MUTATION_LOG"
        [[ $MKDIR_STATUS -eq 0 ]] || return "$MKDIR_STATUS"
    fi
    command mkdir "$@"
}
state_get() {
    local domain="$1"
    local key="$2"
    local field="$3"
    awk -F '|' -v domain="$domain" -v key="$key" -v field="$field" \
        '$1 == domain && $2 == key { print $field; found=1; exit } END { if (!found) exit 1 }' \
        "$STATE_FILE"
}
state_set() {
    local domain="$1"
    local key="$2"
    local type="$3"
    local value="$4"
    awk -F '|' -v domain="$domain" -v key="$key" \
        '$1 != domain || $2 != key' "$STATE_FILE" > "$STATE_FILE.next"
    printf '%s|%s|%s|%s\n' "$domain" "$key" "$type" "$value" >> "$STATE_FILE.next"
    mv "$STATE_FILE.next" "$STATE_FILE"
}
defaults() {
    local operation="$1"
    local domain="$2"
    local key="$3"

    printf '%s:%s:%s\n' "$operation" "$domain" "$key" >> "$OBSERVATION_LOG"

    case "$operation" in
        read-type)
            if [[ "$READ_TYPE_FAILURE" == "$domain|$key" ]]; then
                echo "unexpected defaults failure" >&2
                return 2
            fi
            local native_type
            native_type="$(state_get "$domain" "$key" 3)" || {
                echo "The domain/default pair of ($domain, $key) does not exist" >&2
                return 1
            }
            case "$native_type" in
                bool) echo "Type is boolean" ;;
                int) echo "Type is integer" ;;
                string) echo "Type is string" ;;
                *) echo "Type is $native_type" ;;
            esac
            ;;
        read)
            [[ "$READ_FAILURE" != "$domain|$key" ]] || return 2
            state_get "$domain" "$key" 4
            ;;
        write)
            printf 'write:%s:%s:%s:%s\n' "$domain" "$key" "$4" "$5" >> "$MUTATION_LOG"
            [[ $WRITE_STATUS -eq 0 ]] || return "$WRITE_STATUS"
            local native_type="${4#-}"
            local written_value="$5"
            if [[ "$POST_WRITE_MODE" == mismatch ]]; then
                written_value="unexpected"
            elif [[ "$POST_WRITE_MODE" == observation-error ]]; then
                READ_TYPE_FAILURE="$domain|$key"
            fi
            state_set "$domain" "$key" "$native_type" "$written_value"
            ;;
        *) return 2 ;;
    esac
}

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; ((TEST_FAILURES++)); }
expect_status() {
    local expected="$1" actual="$2" label="$3"
    [[ "$actual" -eq "$expected" ]] && pass "$label" || fail "$label (expected $expected, got $actual)"
}
assert_no_mutation() {
    [[ ! -s "$MUTATION_LOG" ]] && pass "$1" || fail "$1"
}
assert_no_success() {
    if grep -Eq 'configured successfully|already configured' <<< "$1"; then
        fail "$2"
    else
        pass "$2"
    fi
}
reset_case() {
    : > "$STATE_FILE"
    : > "$MUTATION_LOG"
    : > "$OBSERVATION_LOG"
    : > "$FINDER_CONFIG"
    : > "$DOCK_CONFIG"
    : > "$KEYBOARD_CONFIG"
    : > "$TRACKPAD_CONFIG"
    : > "$SCREENSHOTS_CONFIG"
    rm -rf "$HOME/Screenshots"
    MODULE_CHANGED=false
    ENABLED_CATEGORIES="all"
    READ_TYPE_FAILURE=""
    READ_FAILURE=""
    WRITE_STATUS=0
    POST_WRITE_MODE="match"
    KILLALL_STATUS=0
    MKDIR_STATUS=0
    MACOS_APPLY_FAILED=false
}

# Valid matching values retain type-safe, configured-empty semantics.
reset_case
cat > "$FINDER_CONFIG" <<EOF
test.domain|boolKey|bool|true
test.domain|intKey|int|-3
test.domain|emptyKey|string|
test.domain|spaceKey|string|value with spaces
EOF
state_set test.domain boolKey bool 1
state_set test.domain intKey int -03
state_set test.domain emptyKey string ""
state_set test.domain spaceKey string "value with spaces"
check_defaults_config "$FINDER_CONFIG"; status=$?
expect_status 0 "$status" "matching bool, int, empty string, and spaced string are accepted"
assert_no_mutation "matching valid configuration performs no mutation"

# Complete-file validation blocks all writes, including a valid first record.
validation_cases=(
    'test.domain|key|bool|true|extra'
    'test.domain|key|float|1.5'
    'test.domain|key|bool|maybe'
    'test.domain|key|int|1.5'
)
validation_labels=(
    'wrong field count'
    'unsupported type'
    'invalid bool'
    'invalid int'
)
for ((index=0; index<${#validation_cases[@]}; index++)); do
    reset_case
    printf 'test.domain|first|string|desired\n%s\n' "${validation_cases[$index]}" > "$FINDER_CONFIG"
    apply_defaults_config "$FINDER_CONFIG" >/dev/null 2>&1; status=$?
    expect_status 2 "$status" "${validation_labels[$index]} returns 2"
    assert_no_mutation "${validation_labels[$index]} blocks the valid earlier record"
done

reset_case
printf 'malformed\n' > "$FINDER_CONFIG"
apply_defaults_config "$FINDER_CONFIG" >/dev/null 2>&1; status=$?
expect_status 2 "$status" "malformed record returns 2"
assert_no_mutation "malformed record performs zero mutation"

# Observation is tri-state: absence differs; unexpected failures are errors.
reset_case
printf 'test.domain|key|string|desired\n' > "$FINDER_CONFIG"
check_defaults_config "$FINDER_CONFIG"; status=$?
expect_status 1 "$status" "legitimate preference absence is a difference"
apply_defaults_config "$FINDER_CONFIG" >/dev/null; status=$?
expect_status 0 "$status" "legitimate absence can be applied and verified"
[[ "$MODULE_CHANGED" == true ]] && pass "verified absent preference application records change" || fail "absent preference application did not record change"

reset_case
printf 'test.domain|key|string|desired\n' > "$FINDER_CONFIG"
READ_TYPE_FAILURE='test.domain|key'
apply_defaults_config "$FINDER_CONFIG" >/dev/null 2>&1; status=$?
expect_status 2 "$status" "unexpected read-type failure returns 2"
assert_no_mutation "read-type failure performs zero mutation"

reset_case
printf 'test.domain|key|string|desired\n' > "$FINDER_CONFIG"
state_set test.domain key string current
READ_FAILURE='test.domain|key'
apply_defaults_config "$FINDER_CONFIG" >/dev/null 2>&1; status=$?
expect_status 2 "$status" "unexpected value-read failure returns 2"
assert_no_mutation "value-read failure performs zero mutation"

reset_case
printf 'test.domain|key|string|desired\n' > "$FINDER_CONFIG"
state_set test.domain key int 1
apply_defaults_config "$FINDER_CONFIG" >/dev/null 2>&1; status=$?
expect_status 2 "$status" "incompatible observed native type returns 2"
assert_no_mutation "incompatible native type performs zero mutation"

reset_case
printf 'test.domain|key|int|2\n' > "$FINDER_CONFIG"
state_set test.domain key int malformed
apply_defaults_config "$FINDER_CONFIG" >/dev/null 2>&1; status=$?
expect_status 2 "$status" "malformed observed integer returns 2"
assert_no_mutation "malformed observed integer performs zero mutation"

# Apply and verify failures are truthful.
reset_case
printf 'test.domain|key|int|2\n' > "$KEYBOARD_CONFIG"
state_set test.domain key int 1
apply_defaults_config "$KEYBOARD_CONFIG" >/dev/null; status=$?
expect_status 0 "$status" "different valid preference is written and verified"
[[ "$(state_get test.domain key 4)" == 2 ]] && pass "successful mutation reaches desired state" || fail "successful mutation stored wrong state"

reset_case
printf 'test.domain|key|string|desired\n' > "$KEYBOARD_CONFIG"
state_set test.domain key string current
WRITE_STATUS=2
output="$(apply_keyboard_settings 2>&1)"; status=$?
expect_status 2 "$status" "failed defaults write returns 2"
assert_no_success "$output" "failed defaults write emits no category success"
[[ "$MODULE_CHANGED" == false ]] && pass "failed defaults write reports no change" || fail "failed defaults write reported change"

reset_case
printf 'test.domain|key|string|desired\n' > "$KEYBOARD_CONFIG"
state_set test.domain key string current
ENABLED_CATEGORIES='macos-keyboard'
WRITE_STATUS=2
output="$(apply_macos_settings 2>&1)"; status=$?
expect_status 2 "$status" "failed category mutation remains error through macOS lifecycle"
assert_no_success "$output" "failed category mutation emits no macOS completion success"

reset_case
printf 'test.domain|key|string|desired\n' > "$KEYBOARD_CONFIG"
state_set test.domain key string current
POST_WRITE_MODE=mismatch
output="$(apply_keyboard_settings 2>&1)"; status=$?
expect_status 2 "$status" "post-apply mismatch returns 2"
assert_no_success "$output" "post-apply mismatch emits no category success"

reset_case
printf 'test.domain|key|string|desired\n' > "$KEYBOARD_CONFIG"
state_set test.domain key string current
POST_WRITE_MODE=observation-error
output="$(apply_keyboard_settings 2>&1)"; status=$?
expect_status 2 "$status" "post-apply observation failure returns 2"
assert_no_success "$output" "post-apply observation failure emits no category success"

reset_case
printf 'test.domain|key|string|desired\n' > "$FINDER_CONFIG"
state_set test.domain key string current
KILLALL_STATUS=2
output="$(apply_finder_settings 2>&1)"; status=$?
expect_status 2 "$status" "failed related restart mutation returns 2"
assert_no_success "$output" "failed related restart emits no category success"

# Screenshots validates the complete file before its directory mutation.
reset_case
printf 'test.domain|valid|string|desired\nmalformed\n' > "$SCREENSHOTS_CONFIG"
output="$(apply_screenshots_settings 2>&1)"; status=$?
expect_status 2 "$status" "malformed Screenshots configuration returns 2"
assert_no_mutation "malformed Screenshots configuration performs no mkdir or defaults write"
assert_no_success "$output" "malformed Screenshots configuration emits no success"

reset_case
printf 'test.domain|location|string|desired\n' > "$SCREENSHOTS_CONFIG"
state_set test.domain location string current
apply_screenshots_settings >/dev/null 2>&1; status=$?
expect_status 0 "$status" "valid differing Screenshots configuration applies normally"
if [[ -d "$HOME/Screenshots" && "$MODULE_CHANGED" == true &&
      "$(grep -c '^write:' "$MUTATION_LOG")" -eq 1 ]]; then
    pass "valid Screenshots configuration creates directory and writes preference"
else
    fail "valid Screenshots configuration did not preserve directory/apply behavior"
fi

reset_case
printf 'test.domain|location|string|desired\n' > "$SCREENSHOTS_CONFIG"
state_set test.domain location string current
MKDIR_STATUS=2
output="$(apply_screenshots_settings 2>&1)"; status=$?
expect_status 2 "$status" "Screenshots mkdir failure returns 2"
[[ "$(grep -c '^write:' "$MUTATION_LOG" || true)" -eq 0 ]] && pass "Screenshots mkdir failure blocks defaults write" || fail "Screenshots mkdir failure reached defaults write"
assert_no_success "$output" "Screenshots mkdir failure emits no success"

# Blueprint skips disabled category files and preserves enabled/no-Blueprint behavior.
reset_case
rm -f "$DOCK_CONFIG" "$KEYBOARD_CONFIG" "$TRACKPAD_CONFIG" "$SCREENSHOTS_CONFIG"
ENABLED_CATEGORIES='macos-finder'
check_macos_settings; status=$?
expect_status 0 "$status" "disabled Blueprint categories skip validation"
assert_no_mutation "disabled Blueprint categories perform no mutation"

reset_case
printf 'test.domain|key|string|desired\n' > "$KEYBOARD_CONFIG"
state_set test.domain key string current
ENABLED_CATEGORIES='macos-keyboard'
apply_macos_settings >/dev/null 2>&1; status=$?
expect_status 0 "$status" "enabled Blueprint category retains apply behavior"

reset_case
printf 'test.domain|key|string|desired\n' > "$KEYBOARD_CONFIG"
state_set test.domain key string desired
apply_macos_settings >/dev/null 2>&1; status=$?
expect_status 0 "$status" "no-Blueprint all-category behavior remains compatible"

# Local errors retain lifecycle status 2.
reset_case
printf 'test.domain|key|int|invalid\n' > "$FINDER_CONFIG"
ERROR_COUNT=0
WARNING_COUNT=0
MODULES_CHECKED=0
run_module "macOS Consumer" check_finder >/dev/null 2>&1; status=$?
expect_status 2 "$status" "local macOS consumer error reaches run_module"
[[ "$ERROR_COUNT" -eq 1 ]] && pass "run_module records macOS consumer error" || fail "run_module lost macOS consumer error"
later_success() { return 0; }
run_module "Later Success" later_success >/dev/null 2>&1
toolkit_exit_code; status=$?
expect_status 2 "$status" "later success cannot erase macOS consumer error"

# Repeated category checks retain exact 0/1/2 orchestration semantics.
CHECK_FINDER_STATUS=0
CHECK_DOCK_STATUS=0
check_finder() { return "$CHECK_FINDER_STATUS"; }
check_dock() { return "$CHECK_DOCK_STATUS"; }
apply_finder_settings() { printf 'apply:finder\n' >> "$MUTATION_LOG"; return 0; }
apply_dock_settings() { printf 'apply:dock\n' >> "$MUTATION_LOG"; return 0; }

reset_case
ENABLED_CATEGORIES='macos-finder'
CHECK_FINDER_STATUS=0
apply_macos_components >/dev/null 2>&1; status=$?
expect_status 0 "$status" "repeat category check 0 remains satisfied"
assert_no_mutation "repeat category check 0 does not apply"

reset_case
ENABLED_CATEGORIES='macos-finder'
CHECK_FINDER_STATUS=1
apply_macos_components >/dev/null 2>&1; status=$?
expect_status 0 "$status" "repeat category check 1 applies successfully"
[[ "$(cat "$MUTATION_LOG")" == 'apply:finder' ]] && pass "repeat category check 1 calls apply" || fail "repeat category check 1 did not call apply"

reset_case
ENABLED_CATEGORIES=$'macos-finder\nmacos-dock'
CHECK_FINDER_STATUS=2
CHECK_DOCK_STATUS=1
apply_macos_components >/dev/null 2>&1; status=$?
expect_status 2 "$status" "repeat category check 2 remains error"
if [[ "$(cat "$MUTATION_LOG")" == 'apply:dock' && "$MACOS_APPLY_FAILED" == true ]]; then
    pass "check error skips its apply and later category success cannot erase it"
else
    fail "check error reached apply or was erased by later category"
fi

reset_case
ENABLED_CATEGORIES='macos-finder'
CHECK_FINDER_STATUS=7
apply_macos_components >/dev/null 2>&1; status=$?
expect_status 2 "$status" "unexpected repeat category status is treated as error 2"
assert_no_mutation "unexpected repeat category status does not apply"

echo
if [[ $TEST_FAILURES -eq 0 ]]; then
    echo "All macOS Bootstrap consumer safety tests passed"
    exit 0
fi

echo "$TEST_FAILURES macOS Bootstrap test(s) failed" >&2
exit 1
