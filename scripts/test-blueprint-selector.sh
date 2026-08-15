#!/bin/bash

# ==========================================
# Blueprint Selector Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

BLUEPRINT_FILE="$TEST_ROOT/config/blueprint.conf"
BLUEPRINT_GENERATED_DIR="$TEST_ROOT/generated"
TEST_FAILURES=0

warning() { :; }
error() { echo "[ERROR] $1"; }
info() { :; }
success() { echo "[ OK ] $1"; }

source "$PROJECT_ROOT/modules/core/config/config.sh"
source "$PROJECT_ROOT/modules/blueprint/blueprint.sh"
source "$PROJECT_ROOT/modules/blueprint/selector.sh"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; ((TEST_FAILURES++)); }

expect_parse() {
    local label="$1"
    local input="$2"
    local count="$3"
    local expected="$4"
    local actual

    if blueprint_selector_parse_numbers "$input" "$count"; then
        actual="${BLUEPRINT_PARSED_INDICES[*]}"
    else
        actual=invalid
    fi

    [[ "$actual" == "$expected" ]] && pass "$label" || \
        fail "$label (expected '$expected', got '$actual')"
}

write_generated() {
    mkdir -p "$BLUEPRINT_GENERATED_DIR/workspace"
    printf '%s\n' package-{1..12} > "$BLUEPRINT_GENERATED_DIR/brew-packages.conf"
    echo cask-one > "$BLUEPRINT_GENERATED_DIR/brew-casks.conf"
    echo '111|Example App' > "$BLUEPRINT_GENERATED_DIR/appstore.conf"
    echo publisher.extension > "$BLUEPRINT_GENERATED_DIR/vscode-extensions.conf"
    echo 'Projects|workspace' > "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"
    {
        echo '[project-one]'
        echo 'PATH="/example/project-one"'
    } > "$BLUEPRINT_GENERATED_DIR/workspace/repositories.conf"
}

write_existing_blueprint() {
    mkdir -p "$(dirname "$BLUEPRINT_FILE")"
    {
        echo '[categories]'
        echo 'git-configuration="false"'
        echo 'vscode-settings="true"'
        echo 'macos-finder="true"'
        echo 'macos-dock="true"'
        echo 'macos-keyboard="true"'
        echo 'macos-trackpad="true"'
        echo 'macos-screenshots="true"'
        echo
        echo '[homebrew-packages]'
        echo 'package-1'
        echo
        echo '[homebrew-casks]'
        echo 'cask-one'
        echo
        echo '[app-store]'
        echo '111'
        echo
        echo '[vscode-extensions]'
        echo 'publisher.extension'
        echo
        echo '[workspace-folders]'
        echo 'Projects'
        echo
        echo '[git-repositories]'
        echo 'project-one'
    } > "$BLUEPRINT_FILE"
}

expect_parse "comma-separated numbers" "1,3,5" 10 "0 2 4"
expect_parse "space-separated numbers" "1 3 5" 10 "0 2 4"
expect_parse "range" "5-9" 10 "4 5 6 7 8"
expect_parse "mixed numbers and range" "1,3,7-10" 10 "0 2 6 7 8 9"
expect_parse "duplicate numbers are de-duplicated" "1,1,1-2" 10 "0 1"
expect_parse "malformed token is invalid" "1,x" 10 invalid
expect_parse "reversed range is invalid" "9-5" 10 invalid
expect_parse "out-of-range number is invalid" "11" 10 invalid
expect_parse "zero in numeric selection is invalid" "1,0" 10 invalid
expect_parse "negative number is invalid" "-1" 10 invalid

BLUEPRINT_SELECTOR_SELECTED=(true true true)
before="${BLUEPRINT_SELECTOR_SELECTED[*]}"
if ! blueprint_selector_parse_numbers "1,bad,3" 3 &&
   [[ "${BLUEPRINT_SELECTOR_SELECTED[*]}" == "$before" ]]; then
    pass "invalid input causes no partial selection changes"
else
    fail "invalid input changed pending selection"
fi

write_generated
blueprint_selector_load_items homebrew-packages
blueprint_selector_choose_items homebrew-packages "Packages" <<< "" >/dev/null
[[ "${BLUEPRINT_SELECTOR_SELECTED[*]}" == "true true true true true true true true true true true true" ]] && \
    pass "Enter preserves the new Blueprint initial All selection" || \
    fail "Enter changed the new Blueprint initial selection"

blueprint_selector_choose_items homebrew-packages "Packages" <<< "N" >/dev/null
[[ "${BLUEPRINT_SELECTOR_SELECTED[*]}" == "false false false false false false false false false false false false" ]] && \
    pass "None clears an item category" || fail "None did not clear an item category"
blueprint_selector_choose_items homebrew-packages "Packages" <<< "A" >/dev/null
[[ "${BLUEPRINT_SELECTOR_SELECTED[*]}" == "true true true true true true true true true true true true" ]] && \
    pass "All selects an item category" || fail "All did not select an item category"

blueprint_selector_load_items homebrew-packages
blueprint_selector_choose_items homebrew-packages "Packages" <<< $'e\n1,3\nd' >/dev/null
if [[ "${BLUEPRINT_SELECTOR_SELECTED[0]}" == false &&
      "${BLUEPRINT_SELECTOR_SELECTED[1]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[2]}" == false ]]; then
    pass "Edit mode toggles requested items"
else
    fail "Edit mode did not preserve pending checkbox state"
fi

before="${BLUEPRINT_SELECTOR_SELECTED[*]}"
blueprint_selector_select_items "Packages" <<< "" >/dev/null
[[ "${BLUEPRINT_SELECTOR_SELECTED[*]}" == "$before" ]] &&
    pass "Enter exits Edit while preserving checkbox state" ||
    fail "Enter inside Edit changed checkbox state"

blueprint_selector_set_all false
blueprint_selector_select_items "Packages" <<< $'2-4\n' >/dev/null
if [[ "${BLUEPRINT_SELECTOR_SELECTED[0]}" == false &&
      "${BLUEPRINT_SELECTOR_SELECTED[1]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[2]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[3]}" == true ]]; then
    pass "ranges toggle checkbox state"
else
    fail "range input did not toggle checkbox state"
fi

blueprint_selector_set_all false
blueprint_selector_select_items "Packages" <<< $'1,3,7-10\n' >/dev/null
if [[ "${BLUEPRINT_SELECTOR_SELECTED[0]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[2]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[6]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[9]}" == true ]]; then
    pass "mixed input toggles checkbox state"
else
    fail "mixed input did not toggle checkbox state"
fi

blueprint_selector_set_all true
before="${BLUEPRINT_SELECTOR_SELECTED[*]}"
invalid_command_output="$(blueprint_selector_choose_items homebrew-packages "Packages" <<< $'s\n')"
if grep -q 'Choose A, N, or E.' <<< "$invalid_command_output" &&
   [[ "${BLUEPRINT_SELECTOR_SELECTED[*]}" == "$before" ]]; then
    pass "S is rejected and no longer enters Edit mode"
else
    fail "S remains accepted or changed selection"
fi

blueprint_selector_set_all true
pagination_output="$(blueprint_selector_select_items "Packages" <<< $'p\nn\nn\np\nd')"
if grep -q 'Packages — 1/2' <<< "$pagination_output" &&
   grep -q 'Packages — 2/2' <<< "$pagination_output" &&
   grep -q '11\. \[x\] package-11' <<< "$pagination_output"; then
    pass "pagination boundaries keep stable global numbering"
else
    fail "pagination or stable numbering failed"
fi

write_existing_blueprint
blueprint_selector_load_items homebrew-packages
if [[ "${BLUEPRINT_SELECTOR_SELECTED[0]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[1]}" == false ]]; then
    pass "existing selection loads and new discovered items stay unselected"
else
    fail "existing Blueprint item state was reset"
fi

before="${BLUEPRINT_SELECTOR_SELECTED[*]}"
blueprint_selector_choose_items homebrew-packages "Packages" <<< "" >/dev/null
if [[ "${BLUEPRINT_SELECTOR_SELECTED[*]}" == "$before" &&
      "${BLUEPRINT_SELECTOR_SELECTED[0]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[1]}" == false ]]; then
    pass "Enter preserves existing partial and newly discovered item state"
else
    fail "Enter changed existing partial Blueprint selection"
fi

BLUEPRINT_GIT_CONFIGURATION=true
blueprint_selector_prompt_category git-configuration "Git" BLUEPRINT_GIT_CONFIGURATION <<< "" >/dev/null
[[ "$BLUEPRINT_GIT_CONFIGURATION" == false ]] && \
    pass "existing false category is the prompt default" || \
    fail "existing category default was not preserved"

missing_root="$TEST_ROOT/missing"
BLUEPRINT_GENERATED_DIR="$missing_root/generated"
BLUEPRINT_FILE="$missing_root/blueprint.conf"
if ! blueprint_selector_run </dev/null >/dev/null 2>&1 && [[ ! -e "$BLUEPRINT_FILE" ]]; then
    pass "missing generated state refuses without creating Blueprint"
else
    fail "missing generated state was not handled safely"
fi

BLUEPRINT_GENERATED_DIR="$TEST_ROOT/generated"
BLUEPRINT_FILE="$TEST_ROOT/new/blueprint.conf"
mkdir -p "$(dirname "$BLUEPRINT_FILE")"
wizard_defaults=$'\n\n\n\n\n\n\n\n\n\n\n\n\n\n'
summary_output="$(blueprint_selector_run <<< "$wizard_defaults")"
if [[ -f "$BLUEPRINT_FILE" ]] && blueprint_validate "$BLUEPRINT_FILE" &&
   grep -q 'Homebrew packages.*12 / 12' <<< "$summary_output" &&
   grep -q 'Git Configuration.*Yes' <<< "$summary_output" &&
   grep -q 'git-configuration="true"' "$BLUEPRINT_FILE"; then
    pass "new Blueprint defaults, summary, and validated save"
else
    fail "new Blueprint default save failed"
fi

write_existing_blueprint
before_checksum="$(cksum "$BLUEPRINT_FILE")"
cancel_input=$'\n\n\n\n\n\n\n\n\n\n\n\n\nn'
cancel_output="$(blueprint_selector_run <<< "$cancel_input")"
after_checksum="$(cksum "$BLUEPRINT_FILE")"
if [[ "$before_checksum" == "$after_checksum" ]] &&
   grep -q 'Blueprint changes cancelled; no file changes were saved' <<< "$cancel_output"; then
    pass "declining save reports cancellation and preserves existing Blueprint"
else
    fail "declining save changed existing Blueprint or used unclear output"
fi

rm -f "$BLUEPRINT_FILE"
cancel_output="$(blueprint_selector_run <<< "$cancel_input")"
if [[ ! -e "$BLUEPRINT_FILE" ]] &&
   [[ -z "$(find "$(dirname "$BLUEPRINT_FILE")" -name 'blueprint.conf.tmp.*' -print)" ]] &&
   grep -q 'Blueprint changes cancelled; no file changes were saved' <<< "$cancel_output"; then
    pass "declining new Blueprint leaves no file or partial temporary file"
else
    fail "cancelled Blueprint left output behind"
fi

if grep -q -- '--blueprint)' "$PROJECT_ROOT/bootstrap.sh" &&
   "$PROJECT_ROOT/bootstrap.sh" --help | grep -q -- '--blueprint'; then
    pass "CLI recognizes and documents --blueprint"
else
    fail "CLI --blueprint integration missing"
fi

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo
    echo "$TEST_FAILURES Blueprint selector test(s) failed"
    exit 1
fi

echo
echo "All Blueprint selector tests passed"
