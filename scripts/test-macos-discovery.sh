#!/bin/bash

# ==========================================
# macOS Discovery Safe Publication Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

TEST_FAILURES=0
VERBOSE=false
MOCK_MODE=normal
MOCK_TARGET=""
SUCCESS_MESSAGES=""
WARNING_MESSAGES=""
ERROR_MESSAGES=""

source "$PROJECT_ROOT/modules/core/common/common.sh"
source "$PROJECT_ROOT/modules/discovery/discovery.sh"

log() { :; }
action() { :; }
detail() { :; }
success() {
    SUCCESS_MESSAGES="${SUCCESS_MESSAGES}${SUCCESS_MESSAGES:+
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

mock_native_type() {
    case "$1" in
        AppleShowAllExtensions|ShowPathbar|ShowStatusBar|_FXSortFoldersFirst|FXRemoveOldTrashItems|autohide|show-recents|magnification|Clicking|TrackpadRightClick)
            echo "Type is boolean"
            ;;
        tilesize|largesize|KeyRepeat|InitialKeyRepeat|com.apple.trackpad.scaling)
            echo "Type is integer"
            ;;
        FXPreferredViewStyle|FXDefaultSearchScope|location)
            echo "Type is string"
            ;;
        *)
            return 2
            ;;
    esac
}

mock_value() {
    case "$1" in
        AppleShowAllExtensions|ShowStatusBar|_FXSortFoldersFirst|autohide|magnification|Clicking)
            echo 1
            ;;
        ShowPathbar|FXRemoveOldTrashItems|show-recents|TrackpadRightClick)
            echo 0
            ;;
        tilesize) echo 48 ;;
        largesize) echo 64 ;;
        KeyRepeat) echo 2 ;;
        InitialKeyRepeat) echo 15 ;;
        com.apple.trackpad.scaling) echo 2 ;;
        FXPreferredViewStyle) echo Nlsv ;;
        FXDefaultSearchScope) echo SCcf ;;
        location) echo "/Users/test/Screen Shots" ;;
        *) return 2 ;;
    esac
}

defaults() {
    local operation="$1"
    local domain="$2"
    local key="$3"
    local identity="$domain|$key"

    if [[ "$MOCK_MODE" == all_absent ||
          ( "$MOCK_MODE" == absent && "$identity" == "$MOCK_TARGET" ) ]]; then
        echo "The domain/default pair of ($domain, $key) does not exist" >&2
        return 1
    fi

    if [[ "$identity" == "$MOCK_TARGET" ]]; then
        case "$MOCK_MODE" in
            type_failure)
                echo "Preferences service unavailable" >&2
                return 1
                ;;
            type_mismatch)
                if [[ "$operation" == read-type ]]; then
                    echo "Type is string"
                    return 0
                fi
                ;;
            value_failure)
                if [[ "$operation" == read ]]; then
                    echo "Preferences read failed" >&2
                    return 1
                fi
                ;;
            empty_string)
                if [[ "$operation" == read ]]; then
                    return 0
                fi
                ;;
        esac
    fi

    case "$operation" in
        read-type) mock_native_type "$key" ;;
        read) mock_value "$key" ;;
        *) return 2 ;;
    esac
}

source "$PROJECT_ROOT/modules/discovery/macos/macos.sh"

ORIGINAL_SERIALIZE_FINDER="$(declare -f serialize_finder_settings)"
ORIGINAL_EXPORT_FINDER="$(declare -f export_finder_settings)"
ORIGINAL_EXPORT_DOCK="$(declare -f export_dock_settings)"
ORIGINAL_EXPORT_KEYBOARD="$(declare -f export_keyboard_settings)"
ORIGINAL_EXPORT_TRACKPAD="$(declare -f export_trackpad_settings)"
ORIGINAL_EXPORT_SCREENSHOTS="$(declare -f export_screenshots_settings)"

pass() { echo "PASS: $1"; }
fail() {
    echo "FAIL: $1"
    ((TEST_FAILURES++))
}

reset_functions() {
    eval "$ORIGINAL_SERIALIZE_FINDER"
    eval "$ORIGINAL_EXPORT_FINDER"
    eval "$ORIGINAL_EXPORT_DOCK"
    eval "$ORIGINAL_EXPORT_KEYBOARD"
    eval "$ORIGINAL_EXPORT_TRACKPAD"
    eval "$ORIGINAL_EXPORT_SCREENSHOTS"
}

reset_fixture() {
    reset_functions
    rm -rf "$TEST_ROOT/config"
    mkdir -p "$TEST_ROOT/config/generated/macos"
    MOCK_MODE=normal
    MOCK_TARGET=""
    SUCCESS_MESSAGES=""
    WARNING_MESSAGES=""
    ERROR_MESSAGES=""
}

reset_counters() {
    MODULES_CHECKED=0
    INSTALLED_COUNT=0
    SKIPPED_COUNT=0
    WARNING_COUNT=0
    ERROR_COUNT=0
}

temporary_files() {
    find config/generated/macos -type f -name '*.tmp.*' -print 2>/dev/null
}

cd "$TEST_ROOT" || exit 1

# ==========================================
# Normal populated formats for all categories
# ==========================================

reset_fixture
export_finder_settings >/dev/null
finder_status=$?
expected_finder=$'NSGlobalDomain|AppleShowAllExtensions|bool|1\ncom.apple.finder|ShowPathbar|bool|0\ncom.apple.finder|ShowStatusBar|bool|1\ncom.apple.finder|FXPreferredViewStyle|string|Nlsv\ncom.apple.finder|FXDefaultSearchScope|string|SCcf\ncom.apple.finder|_FXSortFoldersFirst|bool|1\ncom.apple.finder|FXRemoveOldTrashItems|bool|0'
if [[ $finder_status -eq 0 && "$(cat config/generated/macos/finder.conf)" == "$expected_finder" ]]; then
    pass "Finder present bool and string preferences preserve the existing format"
else
    fail "Finder populated format changed"
fi

reset_fixture
export_dock_settings >/dev/null
dock_status=$?
expected_dock=$'com.apple.dock|autohide|bool|1\ncom.apple.dock|show-recents|bool|0\ncom.apple.dock|tilesize|int|48\ncom.apple.dock|magnification|bool|1\ncom.apple.dock|largesize|int|64'
if [[ $dock_status -eq 0 && "$(cat config/generated/macos/dock.conf)" == "$expected_dock" ]]; then
    pass "Dock present bool and int preferences preserve the existing format"
else
    fail "Dock populated format changed"
fi

reset_fixture
export_keyboard_settings >/dev/null
if [[ $? -eq 0 && "$(cat config/generated/macos/keyboard.conf)" == $'NSGlobalDomain|KeyRepeat|int|2\nNSGlobalDomain|InitialKeyRepeat|int|15' ]]; then
    pass "Keyboard present integer preferences preserve the existing format"
else
    fail "Keyboard populated format changed"
fi

reset_fixture
export_trackpad_settings >/dev/null
if [[ $? -eq 0 && "$(cat config/generated/macos/trackpad.conf)" == $'com.apple.AppleMultitouchTrackpad|Clicking|bool|1\nNSGlobalDomain|com.apple.trackpad.scaling|int|2\ncom.apple.AppleMultitouchTrackpad|TrackpadRightClick|bool|0' ]]; then
    pass "Trackpad present preferences preserve the existing format"
else
    fail "Trackpad populated format changed"
fi

reset_fixture
export_screenshots_settings >/dev/null
if [[ $? -eq 0 && "$(cat config/generated/macos/screenshots.conf)" == 'com.apple.screencapture|location|string|/Users/test/Screen Shots' ]]; then
    pass "Screenshots present string with spaces preserves the existing format"
else
    fail "Screenshots populated format changed"
fi

# ==========================================
# Present empty string and legitimate absence
# ==========================================

reset_fixture
MOCK_MODE=empty_string
MOCK_TARGET='com.apple.screencapture|location'
export_screenshots_settings >/dev/null
empty_string_status=$?
if [[ $empty_string_status -eq 0 &&
      "$(cat config/generated/macos/screenshots.conf)" == 'com.apple.screencapture|location|string|' ]]; then
    pass "configured empty string remains a present serialized preference"
else
    fail "configured empty string was conflated with absence"
fi

reset_fixture
printf 'stale record\n' > config/generated/macos/finder.conf
MOCK_MODE=absent
MOCK_TARGET='com.apple.finder|ShowPathbar'
export_finder_settings >/dev/null
absence_status=$?
if [[ $absence_status -eq 0 &&
      "$(cat config/generated/macos/finder.conf)" == "$expected_finder"$'\n' ]]; then
    fail "absent Finder preference remained serialized"
elif [[ $absence_status -eq 0 ]] &&
     ! grep -q 'ShowPathbar' config/generated/macos/finder.conf &&
     ! grep -q 'stale record' config/generated/macos/finder.conf; then
    pass "legitimate absence omits the record and removes stale generated state"
else
    fail "legitimate absence failed or preserved stale state"
fi

category_functions=(
    export_finder_settings
    export_dock_settings
    export_keyboard_settings
    export_trackpad_settings
    export_screenshots_settings
)
category_files=(finder.conf dock.conf keyboard.conf trackpad.conf screenshots.conf)

for ((category_index = 0; category_index < ${#category_functions[@]}; category_index++)); do
    reset_fixture
    MOCK_MODE=all_absent
    "${category_functions[$category_index]}" >/dev/null
    category_status=$?
    category_file="config/generated/macos/${category_files[$category_index]}"

    if [[ $category_status -eq 0 && -f "$category_file" && ! -s "$category_file" ]]; then
        pass "all-absent ${category_files[$category_index]} publishes a valid empty file"
    else
        fail "all-absent ${category_files[$category_index]} did not publish empty success"
    fi
done

# ==========================================
# Per-category unexpected type-read failures
# ==========================================

category_targets=(
    'NSGlobalDomain|AppleShowAllExtensions'
    'com.apple.dock|autohide'
    'NSGlobalDomain|KeyRepeat'
    'com.apple.AppleMultitouchTrackpad|Clicking'
    'com.apple.screencapture|location'
)

for ((category_index = 0; category_index < ${#category_functions[@]}; category_index++)); do
    reset_fixture
    category_file="config/generated/macos/${category_files[$category_index]}"
    printf 'previous category bytes\n' > "$category_file"
    before_checksum="$(cksum "$category_file")"
    MOCK_MODE=type_failure
    MOCK_TARGET="${category_targets[$category_index]}"
    "${category_functions[$category_index]}" >/dev/null
    category_status=$?
    after_checksum="$(cksum "$category_file")"

    if [[ $category_status -eq 2 && "$before_checksum" == "$after_checksum" &&
          "$SUCCESS_MESSAGES" != *'exported'* && -z "$(temporary_files)" ]]; then
        pass "unexpected read-type failure preserves ${category_files[$category_index]}"
    else
        fail "unexpected read-type failure damaged ${category_files[$category_index]}"
    fi
done

# ==========================================
# Value, type, serializer, and publication failures
# ==========================================

reset_fixture
printf 'previous Finder bytes\n' > config/generated/macos/finder.conf
before_checksum="$(cksum config/generated/macos/finder.conf)"
MOCK_MODE=value_failure
MOCK_TARGET='com.apple.finder|ShowPathbar'
export_finder_settings >/dev/null
failure_status=$?
after_checksum="$(cksum config/generated/macos/finder.conf)"
if [[ $failure_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$ERROR_MESSAGES" == *'Failed to read macOS preference'* &&
      "$SUCCESS_MESSAGES" != *'Finder configuration exported'* && -z "$(temporary_files)" ]]; then
    pass "value-read failure preserves previous generated state"
else
    fail "value-read failure was destructive or falsely successful"
fi

reset_fixture
printf 'previous Dock bytes\n' > config/generated/macos/dock.conf
before_checksum="$(cksum config/generated/macos/dock.conf)"
MOCK_MODE=type_mismatch
MOCK_TARGET='com.apple.dock|autohide'
export_dock_settings >/dev/null
failure_status=$?
after_checksum="$(cksum config/generated/macos/dock.conf)"
if [[ $failure_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$ERROR_MESSAGES" == *'Incompatible macOS preference type'* &&
      "$SUCCESS_MESSAGES" != *'Dock configuration exported'* && -z "$(temporary_files)" ]]; then
    pass "native type mismatch preserves previous generated state"
else
    fail "native type mismatch was destructive or falsely successful"
fi

reset_fixture
printf 'previous Finder bytes\n' > config/generated/macos/finder.conf
before_checksum="$(cksum config/generated/macos/finder.conf)"
serialize_finder_settings() { return 2; }
export_finder_settings >/dev/null
failure_status=$?
after_checksum="$(cksum config/generated/macos/finder.conf)"
if [[ $failure_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$SUCCESS_MESSAGES" != *'Finder configuration exported'* && -z "$(temporary_files)" ]]; then
    pass "macOS serialization failure preserves state and cleans temporary files"
else
    fail "macOS serialization failure changed state or leaked temporary output"
fi

reset_fixture
printf 'previous Finder bytes\n' > config/generated/macos/finder.conf
before_checksum="$(cksum config/generated/macos/finder.conf)"
mv() { return 1; }
export_finder_settings >/dev/null
failure_status=$?
unset -f mv
after_checksum="$(cksum config/generated/macos/finder.conf)"
if [[ $failure_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$SUCCESS_MESSAGES" != *'Finder configuration exported'* && -z "$(temporary_files)" ]]; then
    pass "macOS publication failure preserves state and cleans temporary files"
else
    fail "macOS publication failure changed state or leaked temporary output"
fi

# ==========================================
# macOS controller and run_module propagation
# ==========================================

reset_fixture
discover_macos >/dev/null
if [[ $? -eq 0 && "$SUCCESS_MESSAGES" == *'macOS Discovery completed'* ]]; then
    pass "macOS Discovery controller preserves all-success status 0"
else
    fail "macOS Discovery controller success aggregation changed"
fi

reset_fixture
MOCK_MODE=type_failure
MOCK_TARGET='com.apple.dock|autohide'
discover_macos >/dev/null
if [[ $? -eq 2 && "$ERROR_MESSAGES" == *'macOS Discovery completed with errors'* &&
      "$SUCCESS_MESSAGES" != *'macOS Discovery completed'* ]]; then
    pass "macOS Discovery controller preserves category error status 2"
else
    fail "macOS Discovery controller masked a category error"
fi

reset_fixture
export_finder_settings() { return 1; }
export_dock_settings() { return 0; }
export_keyboard_settings() { return 0; }
export_trackpad_settings() { return 0; }
export_screenshots_settings() { return 0; }
discover_macos >/dev/null
if [[ $? -eq 1 ]]; then
    pass "macOS Discovery controller retains warning status 1"
else
    fail "macOS Discovery controller warning aggregation changed"
fi

for lifecycle_status in 0 1 2; do
    reset_fixture
    reset_counters
    export_finder_settings() { return "$lifecycle_status"; }
    export_dock_settings() { return 0; }
    export_keyboard_settings() { return 0; }
    export_trackpad_settings() { return 0; }
    export_screenshots_settings() { return 0; }

    run_module "macOS Discovery" discover_macos >/dev/null
    actual_status=$?

    if [[ $actual_status -eq $lifecycle_status &&
          $WARNING_COUNT -eq $((lifecycle_status == 1 ? 1 : 0)) &&
          $ERROR_COUNT -eq $((lifecycle_status == 2 ? 1 : 0)) ]]; then
        pass "macOS Discovery run_module propagates $lifecycle_status"
    else
        fail "macOS Discovery run_module failed to propagate $lifecycle_status"
    fi
done

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo
    echo "$TEST_FAILURES macOS Discovery test(s) failed"
    exit 1
fi

echo
echo "All macOS Discovery tests passed"
