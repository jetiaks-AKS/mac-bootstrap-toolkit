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
TOOLKIT_VERSION="test"
MODE="--blueprint"
VERBOSE=false

warning() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1"; }
info() { :; }
success() { echo "[ OK ] $1"; }

source "$PROJECT_ROOT/modules/core/logger/logger.sh"
source "$PROJECT_ROOT/modules/core/config/config.sh"
source "$PROJECT_ROOT/modules/blueprint/blueprint.sh"
source "$PROJECT_ROOT/modules/blueprint/selector.sh"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; ((TEST_FAILURES++)); }

reset_selector_log() {
    LOG_FILE="$TEST_ROOT/selector.log"
    : > "$LOG_FILE"
}

seed_selector_items() {
    local count="$1"
    local index

    BLUEPRINT_SELECTOR_ITEMS=()
    BLUEPRINT_SELECTOR_LABELS=()
    BLUEPRINT_SELECTOR_SELECTED=()
    for ((index = 1; index <= count; index++)); do
        BLUEPRINT_SELECTOR_ITEMS+=("package-$index")
        BLUEPRINT_SELECTOR_LABELS+=("package-$index")
        BLUEPRINT_SELECTOR_SELECTED+=(true)
    done
}

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
        echo 'Desktop'
        echo 'Projects'
        echo 'Library'
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

LOG_DIR="$TEST_ROOT/logs"
LOG_HISTORY_DIR="$LOG_DIR/history"
LATEST_LOG="$LOG_DIR/latest.log"
init_logger
if [[ "$LOG_PREFIX" == blueprint &&
      "$(basename "$LOG_FILE")" == blueprint-*.log &&
      $(grep -c 'Mode     : Blueprint' "$LOG_FILE") -eq 1 ]]; then
    pass "Blueprint logger uses its own prefix and mode header"
else
    fail "Blueprint logger prefix or mode header is incorrect"
fi
close_logger

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

seed_selector_items 20
single_page_output="$(blueprint_selector_select_items "Packages" <<< $'n\nd')"
if grep -q 'Packages — 1/1' <<< "$single_page_output" &&
   grep -q '20\. \[x\] package-20' <<< "$single_page_output" &&
   ! grep -q 'Packages — 2/' <<< "$single_page_output"; then
    pass "20 items fit on one page"
else
    fail "20-item page boundary is incorrect"
fi

seed_selector_items 25
pagination_file="$TEST_ROOT/pagination.out"
blueprint_selector_select_items "Packages" <<< $'p\n19-22\nn\n21\np\nn\nd' > "$pagination_file"
page_two_first_item="$(awk '/Packages — 2\/2/ { on_page_two = 1; next } on_page_two && /\[[x ]\]/ { print $1; exit }' "$pagination_file")"
if grep -q 'Packages — 1/2' "$pagination_file" &&
   grep -q 'Packages — 2/2' "$pagination_file" &&
   [[ "$page_two_first_item" == "21." ]] &&
   grep -q '21\. \[ \] package-21' "$pagination_file" &&
   grep -q '21\. \[x\] package-21' "$pagination_file" &&
   [[ "${BLUEPRINT_SELECTOR_SELECTED[18]}" == false &&
      "${BLUEPRINT_SELECTOR_SELECTED[19]}" == false &&
      "${BLUEPRINT_SELECTOR_SELECTED[20]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[21]}" == false ]]; then
    pass "21+ items paginate with global navigation, toggles, and boundary ranges"
else
    fail "pagination, global numbering, navigation, or boundary selection failed"
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

{
    echo 'Desktop|user'
    echo 'Documents|user'
    echo 'Projects|workspace'
    echo 'Downloads|user'
    echo 'Library|system'
    echo 'Movies|user'
    echo 'Music|user'
    echo 'Pictures|user'
    echo 'Public|system'
    echo 'Screenshots|workspace'
    echo 'Sources|workspace'
    echo 'NewFolder|workspace'
} > "$BLUEPRINT_GENERATED_DIR/workspace/folders.conf"

blueprint_selector_load_items workspace-folders
blueprint_selector_choose_items workspace-folders "Workspace Folders" <<< "N" >/dev/null
blueprint_selector_store_items workspace_selection
if [[ -z "$workspace_selection" ]]; then
    pass "Workspace candidate selection supports None"
else
    fail "Workspace candidate None selection retained items"
fi
blueprint_selector_choose_items workspace-folders "Workspace Folders" <<< "A" >/dev/null
blueprint_selector_store_items workspace_selection
if [[ "$workspace_selection" == $'Projects\nScreenshots\nSources\nNewFolder' ]]; then
    pass "Workspace candidate selection supports All"
else
    fail "Workspace candidate All selection is incomplete"
fi

blueprint_selector_load_items workspace-folders
workspace_output="$(blueprint_selector_select_items "Workspace Folders" <<< $'n\nd')"
blueprint_selector_store_items workspace_selection
if [[ "${BLUEPRINT_SELECTOR_ITEMS[*]}" == "Projects Screenshots Sources NewFolder" &&
      "${BLUEPRINT_SELECTOR_LABELS[*]}" == "Projects Screenshots Sources NewFolder" &&
      "${BLUEPRINT_SELECTOR_SELECTED[0]}" == true &&
      "${BLUEPRINT_SELECTOR_SELECTED[1]}" == false &&
      "${BLUEPRINT_SELECTOR_SELECTED[3]}" == false &&
      "$workspace_selection" == "Projects" &&
      "$(blueprint_selector_count_lines "$workspace_selection")" == 1 &&
      "$workspace_output" == *'  1. [x] Projects'* &&
      "$workspace_output" == *'  2. [ ] Screenshots'* &&
      "$workspace_output" == *'  4. [ ] NewFolder'* &&
      "$workspace_output" != *'Desktop'* &&
      "$workspace_output" != *'Library'* ]]; then
    pass "Workspace selector exposes only classification-driven candidates"
else
    fail "Workspace candidate filtering, labels, or existing selection are incorrect"
fi

blueprint_selector_select_items "Workspace Folders" <<< $'2\nd' >/dev/null
blueprint_selector_store_items workspace_selection
if [[ "${BLUEPRINT_SELECTOR_SELECTED[1]}" == true &&
      "$workspace_selection" == $'Projects\nScreenshots' ]]; then
    pass "Workspace folder toggles store the displayed folder identifier"
else
    fail "Workspace folder toggle did not store the matching identifier"
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
reset_selector_log
summary_output="$(blueprint_selector_run <<< "$wizard_defaults")"
if [[ -f "$BLUEPRINT_FILE" ]] && blueprint_validate "$BLUEPRINT_FILE" &&
   grep -q 'Homebrew packages.*12 / 12' <<< "$summary_output" &&
   grep -q 'Workspace folders.*4 / 4' <<< "$summary_output" &&
   [[ "$(blueprint_selected_items workspace-folders "$BLUEPRINT_FILE")" == $'Projects\nScreenshots\nSources\nNewFolder' ]] &&
   grep -q 'Git Configuration.*Yes' <<< "$summary_output" &&
   grep -q 'git-configuration="true"' "$BLUEPRINT_FILE" &&
   grep -q '\[BLUEPRINT\] START' "$LOG_FILE" &&
   grep -q '\[BLUEPRINT\] Generated configuration: Ready' "$LOG_FILE" &&
   grep -q '\[BLUEPRINT\] RESULT: SAVED' "$LOG_FILE"; then
    pass "new Blueprint save preserves selection and records lifecycle"
else
    fail "new Blueprint save or lifecycle logging failed"
fi

BLUEPRINT_FILE="$TEST_ROOT/config/blueprint.conf"
write_existing_blueprint
reset_selector_log
normalization_output="$(blueprint_selector_run <<< "$wizard_defaults")"
normalized_workspace="$(blueprint_selected_items workspace-folders "$BLUEPRINT_FILE")"
if [[ "$normalized_workspace" == "Projects" ]] &&
   grep -q 'Workspace folders.*1 / 4' <<< "$normalization_output" &&
   ! grep -q '^Desktop$' <<< "$normalized_workspace" &&
   ! grep -q '^Library$' <<< "$normalized_workspace"; then
    pass "save normalizes legacy folders and preserves partial workspace selection"
else
    fail "Workspace selection normalization or candidate count is incorrect"
fi

write_existing_blueprint
before_checksum="$(cksum "$BLUEPRINT_FILE")"
cancel_input=$'\n\n\n\n\n\n\n\n\n\n\n\n\nn'
reset_selector_log
cancel_output="$(blueprint_selector_run <<< "$cancel_input")"
after_checksum="$(cksum "$BLUEPRINT_FILE")"
if [[ "$before_checksum" == "$after_checksum" ]] &&
   grep -q 'Blueprint changes cancelled; no file changes were saved' <<< "$cancel_output" &&
   grep -q '\[BLUEPRINT\] Existing configuration: Valid' "$LOG_FILE" &&
   grep -q '\[BLUEPRINT\] RESULT: CANCELLED' "$LOG_FILE"; then
    pass "cancel preserves existing Blueprint and records lifecycle"
else
    fail "cancel changed existing Blueprint or lifecycle logging is incorrect"
fi

write_existing_blueprint
sed -i.bak 's/package-1/stale-package/' "$BLUEPRINT_FILE"
rm -f "$BLUEPRINT_FILE.bak"
before_checksum="$(cksum "$BLUEPRINT_FILE")"
reset_selector_log
stale_output="$(blueprint_selector_run <<< "$cancel_input")"
stale_status=$?
after_checksum="$(cksum "$BLUEPRINT_FILE")"
if [[ $stale_status -eq 0 && "$before_checksum" == "$after_checksum" ]] &&
   grep -q 'Stale Blueprint item in homebrew-packages: stale-package' <<< "$stale_output" &&
   ! grep -q '\[BLUEPRINT\] Existing configuration: Valid' "$LOG_FILE" &&
   grep -q '\[BLUEPRINT\] RESULT: CANCELLED' "$LOG_FILE"; then
    pass "stale Blueprint preserves warning, exit status, and cancellation"
else
    fail "stale Blueprint lifecycle changed warning or exit semantics"
fi

write_existing_blueprint
echo '[malformed' >> "$BLUEPRINT_FILE"
before_checksum="$(cksum "$BLUEPRINT_FILE")"
reset_selector_log
blueprint_selector_run </dev/null >/dev/null 2>&1
malformed_status=$?
after_checksum="$(cksum "$BLUEPRINT_FILE")"
if [[ $malformed_status -eq 2 && "$before_checksum" == "$after_checksum" ]] &&
   ! grep -q '\[BLUEPRINT\] Existing configuration: Valid' "$LOG_FILE" &&
   ! grep -q '\[BLUEPRINT\] RESULT:' "$LOG_FILE"; then
    pass "malformed Blueprint blocks without false validation or result logging"
else
    fail "malformed Blueprint lifecycle changed validation or exit semantics"
fi

rm -f "$BLUEPRINT_FILE"
reset_selector_log
cancel_output="$(blueprint_selector_run <<< "$cancel_input")"
if [[ ! -e "$BLUEPRINT_FILE" ]] &&
   [[ -z "$(find "$(dirname "$BLUEPRINT_FILE")" -name 'blueprint.conf.tmp.*' -print)" ]] &&
   grep -q 'Blueprint changes cancelled; no file changes were saved' <<< "$cancel_output" &&
   grep -q '\[BLUEPRINT\] RESULT: CANCELLED' "$LOG_FILE"; then
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
