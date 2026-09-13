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
MKDIR_NO_CREATE=false
STAT_FAILURE=false
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
cd "$TEST_ROOT" || exit 1

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
    if [[ "$target" == "$HOME/Captures"* ]]; then
        printf 'mkdir:%s\n' "$target" >> "$MUTATION_LOG"
        [[ $MKDIR_STATUS -eq 0 ]] || return "$MKDIR_STATUS"
        [[ "$MKDIR_NO_CREATE" != true ]] || return 0
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
    chmod u+rwx "$HOME/Captures" 2>/dev/null || :
    rm -rf "$HOME/Captures" "$HOME/Link" "$HOME/Escape" "$HOME/Broken" "$HOME/Loop" "$HOME/Screenshots"
    MODULE_CHANGED=false
    ENABLED_CATEGORIES="all"
    READ_TYPE_FAILURE=""
    READ_FAILURE=""
    WRITE_STATUS=0
    POST_WRITE_MODE="match"
    KILLALL_STATUS=0
    MKDIR_STATUS=0
    MKDIR_NO_CREATE=false
    STAT_FAILURE=false
}

stat() {
    if [[ "$STAT_FAILURE" == true ]]; then echo 'stat: observation failure' >&2; return 2; fi
    command stat "$@"
}
run() {
    "$@" > "$TEST_ROOT/output" 2>&1
    status=$?
    output="$(cat "$TEST_ROOT/output")"
}
record() { printf '%s\n' "$2" > "$1"; }
shots() { printf 'com.apple.screencapture|location|string|%s\n' "$1" > "$SCREENSHOTS_CONFIG"; }
assert_changed() { [[ "$MODULE_CHANGED" == "$1" ]] && pass "$2" || fail "$2"; }
assert_count() {
    local actual
    actual="$(grep -c "$1" "$MUTATION_LOG" || true)"
    [[ "$actual" == "$2" ]] && pass "$3" || fail "$3 ($actual)"
}

# Production schema rejects unsafe records before writes, including late errors.
invalid_records=(
    'com.apple.finder|ShowPathbar|bool|true|extra'
    'unknown.domain|ShowPathbar|bool|true'
    'com.apple.finder|unknown|bool|true'
    'com.apple.dock|autohide|bool|true'
    'com.apple.finder|ShowPathbar|string|true'
    'com.apple.finder|ShowPathbar|bool|maybe'
    'com.apple.finder|FXPreferredViewStyle|string|a|b'
    'malformed'
    $'com.apple.finder|FXPreferredViewStyle|string|a\tb'
    $'com.apple.finder|FXPreferredViewStyle|string|a\nb'
    'com.apple.finder|ShowStatusBar|bool|true'
)
for bad in "${invalid_records[@]}"; do
    reset_case
    printf 'com.apple.finder|ShowStatusBar|bool|true\n%s\n' "$bad" > "$FINDER_CONFIG"
    run apply_defaults_config "$FINDER_CONFIG" finder
    expect_status 2 "$status" "invalid or duplicate category record rejected"
    assert_no_mutation "invalid late record blocks all writes"
done
reset_case
printf 'com.apple.finder|FXPreferredViewStyle|string|a\000b\n' > "$FINDER_CONFIG"
run apply_defaults_config "$FINDER_CONFIG" finder
expect_status 2 "$status" 'NUL rejected before shell parsing'
assert_no_mutation 'NUL record performs no write'

# All existing category identities, empty files, and old integer speed remain valid.
reset_case
for pair in finder dock keyboard trackpad screenshots; do
    run validate_defaults_config "$TEST_ROOT/generated/macos/$pair.conf" "$pair"
    expect_status 0 "$status" "empty $pair remains valid"
done
record "$TRACKPAD_CONFIG" 'NSGlobalDomain|com.apple.trackpad.scaling|int|1'
state_set NSGlobalDomain com.apple.trackpad.scaling int 1
run check_trackpad
expect_status 0 "$status" 'existing integer Trackpad scaling remains valid'
record "$KEYBOARD_CONFIG" 'NSGlobalDomain|KeyRepeat|int|-03'
state_set NSGlobalDomain KeyRepeat int -3
run check_keyboard
expect_status 0 "$status" 'integer normalization preserved without invented ranges'
record "$FINDER_CONFIG" 'com.apple.finder|FXPreferredViewStyle|string|'
state_set com.apple.finder FXPreferredViewStyle string ''
run check_finder
expect_status 0 "$status" 'empty generic string remains present'

# Missing final newline must be read by Check, Preview and Apply.
reset_case
printf 'com.apple.finder|ShowPathbar|bool|true' > "$FINDER_CONFIG"
state_set com.apple.finder ShowPathbar bool 0
run check_finder
expect_status 1 "$status" 'EOF Check observes the final record'
run preview_macos_category "$FINDER_CONFIG" Finder finder
expect_status 0 "$status" 'EOF Preview succeeds'
[[ "$output" == *'false -> true'* ]] && pass 'EOF Preview includes record' || fail 'EOF Preview lost record'
assert_no_mutation 'EOF Preview is read-only'
run apply_defaults_config "$FINDER_CONFIG" finder
expect_status 0 "$status" 'EOF Apply writes and verifies record'
assert_changed true 'EOF Apply records mutation'
: > "$MUTATION_LOG"
MODULE_CHANGED=false
run apply_defaults_config "$FINDER_CONFIG" finder
expect_status 0 "$status" 'second Apply succeeds'
assert_changed false 'second Apply unchanged'
assert_no_mutation 'second Apply has zero writes'

# Tri-state observations, mutation evidence, and failures run in THIS shell.
for mode in match mismatch observation-error write-failure already-correct absent read-error type-error bad-value wrong-type; do
    reset_case
    record "$KEYBOARD_CONFIG" 'NSGlobalDomain|KeyRepeat|int|2'
    state_set NSGlobalDomain KeyRepeat int 1
    expected=2; changed=false
    case "$mode" in
        match) expected=0; changed=true ;;
        mismatch|observation-error) POST_WRITE_MODE="$mode"; changed=true ;;
        write-failure) WRITE_STATUS=2 ;;
        already-correct) state_set NSGlobalDomain KeyRepeat int 2; expected=0 ;;
        absent) : > "$STATE_FILE"; expected=0; changed=true ;;
        read-error) READ_FAILURE='NSGlobalDomain|KeyRepeat' ;;
        type-error) READ_TYPE_FAILURE='NSGlobalDomain|KeyRepeat' ;;
        bad-value) state_set NSGlobalDomain KeyRepeat int malformed ;;
        wrong-type) state_set NSGlobalDomain KeyRepeat string 1 ;;
    esac
    run apply_keyboard_settings
    expect_status "$expected" "$status" "Keyboard $mode status"
    assert_changed "$changed" "Keyboard $mode accounting"
    [[ $expected -eq 0 ]] || assert_no_success "$output" "Keyboard $mode no false success"
    case "$mode" in already-correct|read-error|type-error|bad-value|wrong-type) assert_no_mutation "$mode no mutation" ;; esac
done

# Finder/Dock Preview restart deduplication and Blueprint gates.
reset_case
record "$FINDER_CONFIG" $'com.apple.finder|ShowPathbar|bool|1\ncom.apple.finder|ShowStatusBar|bool|1'
ENABLED_CATEGORIES=macos-finder
MODULE_CHANGED=preserved
run preview_macos_settings
expect_status 0 "$status" 'multiple Finder absent values planned'
[[ "$(grep -c 'Would restart process: Finder' <<< "$output")" == 1 ]] && pass 'Finder restart once' || fail 'Finder restart count'
assert_changed preserved 'Preview preserves MODULE_CHANGED'
assert_no_mutation 'Finder Preview no mutation'
first_preview="$output"
run preview_macos_settings
[[ "$output" == "$first_preview" ]] && pass 'repeated Preview stable' || fail 'unstable Preview'
record "$DOCK_CONFIG" $'com.apple.dock|autohide|bool|1\ncom.apple.dock|show-recents|bool|0'
ENABLED_CATEGORIES=macos-dock
run preview_macos_settings
[[ $status -eq 0 && "$(grep -c 'Would restart process: Dock' <<< "$output")" == 1 ]] && pass 'Dock restart once' || fail 'Dock restart count'
READ_TYPE_FAILURE='com.apple.dock|autohide'
run preview_macos_settings
expect_status 2 "$status" 'Preview observation error'
[[ "$output" != *Would* ]] || fail 'error invented plan'
ENABLED_CATEGORIES=macos-finder
run preview_macos_settings
expect_status 0 "$status" 'disabled Dock not inspected'
KILLALL_STATUS=2
MODULE_CHANGED=false
run apply_finder_settings
expect_status 2 "$status" 'Finder restart failure'
assert_changed true 'Finder restart failure retains writes'
assert_no_success "$output" 'Finder restart failure no success'

# Screenshot path validation: fixtures only, never real user directories.
for bad in '' relative '~otheruser/Shot' '$VAR/Shot' '$HOME/Shot' '${HOME}/Shot' '$(touch sentinel)' '`touch sentinel`' "$HOME/../escape" "$HOME/./bad" "$HOME//bad" $'/tmp/a\nb' $'/tmp/a\tb'; do
    reset_case
    shots "$bad"
    run validate_screenshots_config
    expect_status 2 "$status" "unsafe Screenshot path rejected: $bad"
    assert_no_mutation 'unsafe path has no mutation'
done
[[ ! -e sentinel ]] || fail 'shell data was executed'

reset_case
shots "$HOME/Captures/Nested/Deep"
run check_screenshots
expect_status 1 "$status" 'nested missing destination is creatable'
assert_no_mutation 'nested Check is read-only'
reset_case
shots '~/Captures'
run apply_screenshots_settings
expect_status 0 "$status" 'leading tilde destination restored'
[[ "$(state_get com.apple.screencapture location 4)" == "$HOME/Captures" ]] && pass 'tilde resolved to absolute preference' || fail 'tilde resolution'

reset_case
command mkdir -p "$TEST_ROOT/outside" "$HOME/Captures"
ln -s "$HOME/Captures" "$HOME/Link"
shots "$HOME/Link"
run validate_screenshots_config
expect_status 0 "$status" 'safe internal directory symlink accepted'
ln -s "$TEST_ROOT/outside" "$HOME/Escape"
shots "$HOME/Escape"
run validate_screenshots_config
expect_status 2 "$status" 'HOME escaping symlink rejected'
ln -s "$HOME/missing" "$HOME/Broken"
shots "$HOME/Broken"
run validate_screenshots_config
expect_status 2 "$status" 'dangling symlink rejected'
ln -s "$HOME/Loop" "$HOME/Loop"
shots "$HOME/Loop"
run validate_screenshots_config
expect_status 2 "$status" 'symlink loop rejected'
shots "$TEST_ROOT/outside"
run validate_screenshots_config
expect_status 0 "$status" 'existing writable outside directory accepted'
shots "$TEST_ROOT/missing-outside"
run validate_screenshots_config
expect_status 2 "$status" 'missing outside tree rejected'
shots "/Volumes/toolkit-missing-$RANDOM-$RANDOM/Captures"
run validate_screenshots_config
expect_status 2 "$status" 'missing mount destination rejected'
reset_case
printf file > "$HOME/Captures"
shots "$HOME/Captures"
run validate_screenshots_config
expect_status 2 "$status" 'wrong filesystem type rejected'
reset_case
command mkdir -p "$HOME/Captures"
chmod 000 "$HOME/Captures"
shots "$HOME/Captures"
run validate_screenshots_config
expect_status 2 "$status" 'inaccessible destination rejected'
chmod 700 "$HOME/Captures"
STAT_FAILURE=true
run check_screenshots
expect_status 2 "$status" 'filesystem observation failure is not absence'

# Complete Screenshot Preview decision table, including explicit plan signal.
for mode in noop preference directory both unsafe; do
    reset_case
    shots "$HOME/Captures"
    state_set com.apple.screencapture location string "$HOME/Captures"
    case "$mode" in
        noop|preference) command mkdir -p "$HOME/Captures" ;;
        unsafe) printf file > "$HOME/Captures" ;;
    esac
    case "$mode" in preference|both|unsafe) state_set com.apple.screencapture location string "$HOME/Old" ;; esac
    MODULE_CHANGED=preserved
    PREVIEW_HAS_CHANGES=false
    run preview_screenshots_settings
    if [[ "$mode" == unsafe ]]; then
        expect_status 2 "$status" 'unsafe Preview error'
        [[ "$output" != *Would* && "$PREVIEW_HAS_CHANGES" == false ]] || fail 'unsafe actionable plan'
    else
        expect_status 0 "$status" "Screenshot Preview $mode"
        case "$mode" in
            noop) [[ "$output" != *Would* && "$PREVIEW_HAS_CHANGES" == false ]] || fail 'no-op plan' ;;
            directory)
                [[ "$output" == *'Would create screenshots directory'* && "$output" != *'Would change'* && "$output" != *'Would restart'* && "$PREVIEW_HAS_CHANGES" == true ]] || fail 'mkdir-only Preview' ;;
            preference)
                [[ "$output" != *'Would create'* && "$output" == *'Would change'* && "$output" == *'Would restart'* ]] || fail 'preference-only Preview' ;;
            both)
                [[ "$output" == *'Would create'*'Would change'*'Would restart'* ]] || fail 'both plan order' ;;
        esac
    fi
    assert_changed preserved "Preview $mode preserves accounting"
    assert_no_mutation "Preview $mode no filesystem/preferences/restart"
done

for mode in directory preference both mkdir-failure mkdir-verify write-failure pref-verify pref-read-error restart-failure; do
    reset_case
    shots "$HOME/Captures/Nested"
    state_set com.apple.screencapture location string "$HOME/Old"
    expected=0; changed=true
    case "$mode" in
        directory) state_set com.apple.screencapture location string "$HOME/Captures/Nested" ;;
        preference|write-failure|pref-verify|pref-read-error|restart-failure) command mkdir -p "$HOME/Captures/Nested" ;;
    esac
    case "$mode" in
        mkdir-failure) MKDIR_STATUS=2; expected=2; changed=false ;;
        mkdir-verify) MKDIR_NO_CREATE=true; expected=2 ;;
        write-failure) WRITE_STATUS=2; expected=2; changed=false ;;
        pref-verify) POST_WRITE_MODE=mismatch; expected=2 ;;
        pref-read-error) POST_WRITE_MODE=observation-error; expected=2 ;;
        restart-failure) KILLALL_STATUS=2; expected=2 ;;
    esac
    run apply_screenshots_settings
    expect_status "$expected" "$status" "Screenshot Apply $mode"
    assert_changed "$changed" "Screenshot Apply $mode accounting"
    [[ $expected -eq 0 ]] || assert_no_success "$output" "$mode no false success"
    case "$mode" in
        directory|mkdir-failure|mkdir-verify)
            assert_count '^killall:' 0 "$mode no restart"
            assert_count '^write:' 0 "$mode no preference write" ;;
        preference|both|restart-failure) assert_count '^killall:SystemUIServer' 1 "$mode restart once" ;;
    esac
    [[ ! -e "$HOME/Screenshots" ]] || fail 'unrelated hard-coded directory created'
    if [[ $expected -eq 0 ]]; then
        : > "$MUTATION_LOG"
        MODULE_CHANGED=false
        run apply_screenshots_settings
        expect_status 0 "$status" "$mode second Apply succeeds"
        assert_changed false "$mode second Apply unchanged"
        assert_no_mutation "$mode second Apply no mutations"
    fi
done
reset_case
# Screenshot EOF and missing location retain the documented distinct semantics.
printf 'com.apple.screencapture|location|string|%s' "$HOME/Captures" > "$SCREENSHOTS_CONFIG"
run apply_screenshots_settings
expect_status 0 "$status" 'Screenshot final line without newline restored'
reset_case
run apply_screenshots_settings
expect_status 0 "$status" 'absent location is unmanaged'
assert_no_mutation 'absent location creates no fallback'
ENABLED_CATEGORIES=macos-keyboard
record "$KEYBOARD_CONFIG" 'NSGlobalDomain|KeyRepeat|int|2'
run apply_macos_settings
expect_status 0 "$status" 'enabled category lifecycle remains compatible'
: > "$MUTATION_LOG"
ENABLED_CATEGORIES=all
run apply_macos_settings
expect_status 0 "$status" 'no-Blueprint behavior remains compatible'
assert_no_mutation 'no-Blueprint matching state unchanged'

# Later successful category must not erase a failure or apply an unobserved state.
check_finder() { return 2; }
check_dock() { return 1; }
apply_finder_settings() { fail 'failed Check reached Finder Apply'; }
apply_dock_settings() { printf 'apply:dock\n' >> "$MUTATION_LOG"; return 0; }
ENABLED_CATEGORIES=$'macos-finder\nmacos-dock'
run apply_macos_components
expect_status 2 "$status" 'later category success preserves earlier error'
[[ "$(cat "$MUTATION_LOG")" == apply:dock ]] || fail 'category Check dispatch changed'

[[ $TEST_FAILURES -eq 0 ]] || { echo "$TEST_FAILURES macOS Bootstrap test(s) failed"; exit 1; }
echo 'All macOS Bootstrap consumer safety tests passed'
