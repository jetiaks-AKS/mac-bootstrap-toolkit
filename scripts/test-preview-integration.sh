#!/bin/bash

# Real entrypoint and production modules; only external effects are intercepted.
set -u
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM
FIXTURE="$TEST_ROOT/project"
TEST_FAILURES=0
mkdir -p "$FIXTURE/config"
cp "$PROJECT_ROOT/bootstrap.sh" "$FIXTURE/"
cp -R "$PROJECT_ROOT/modules" "$FIXTURE/"
cp "$PROJECT_ROOT/config/toolkit.conf" "$FIXTURE/config/"
REAL_GIT="$(command -v git)"
export REAL_GIT

# BASH_ENV defines external-command spies, never production lifecycle functions.
cat > "$TEST_ROOT/spies.sh" <<'SPIES'
mutation() { printf '%s\n' "$*" >> "$TEST_MUTATIONS"; return 99; }
observe() { printf '%s\n' "$*" >> "$TEST_OBSERVATIONS"; }
sudo() { mutation "sudo $*"; }
curl() { mutation "curl $*"; }
killall() { mutation "killall $*"; }
mkdir() {
    [[ "$*" == '-p logs/history' ]] || { mutation "mkdir $*"; return 99; }
    command mkdir "$@"
}
cp() {
    [[ "${1:-}" == logs/history/* && "${2:-}" == logs/latest.log ]] || {
        mutation "cp $*"; return 99;
    }
    command cp "$@"
}
mv() {
    if [[ "${TEST_MODE:-}" == --workflow && "$1" == config/blueprint.conf.tmp.* &&
          "$2" == config/blueprint.conf ]]; then
        command mv "$@"
    else
        mutation "mv $*"
    fi
}
# Git validation temporary files are allowed; targets are not.
rm() {
    local arg
    for arg in "$@"; do
        [[ "$arg" == -* || "$arg" == "$TMPDIR"/* ||
           ( ( "${TEST_MODE:-}" == --workflow || "${TEST_MODE:-}" == --blueprint ) && "$arg" == config/blueprint.conf.tmp.* ) ]] || { mutation "rm $*"; return 99; }
    done
    command rm "$@"
}
ping() { observe preflight; [[ "$TEST_CASE" != preflight-error ]]; }
xcode-select() { return 0; }
sw_vers() { echo 99; }
brew() {
    observe "brew $*"
    case "$*" in
        'list --formula --full-name') [[ "$TEST_CASE" != application-error ]] || return 2; echo present ;;
        'list --cask') return 0 ;;
        *) mutation "brew $*" ;;
    esac
}
mas() {
    [[ "$*" == list ]] || { mutation "mas $*"; return 99; }
    observe 'mas list'; echo '111 Present (1.0)'
}
code() {
    [[ "$*" == --list-extensions ]] || { mutation "code $*"; return 99; }
    observe 'code list'; echo publisher.present
}
git() {
    observe "git $*"
    if [[ "${1:-}" == config ]]; then
        case "$*" in
            *--file*--no-includes*) "$REAL_GIT" "$@" ;;
            'config --global --null --get-all '* )
                [[ "$TEST_CASE" != git-error ]] || return 2
                "$REAL_GIT" "$@" ;;
            *) mutation "git $*" ;;
        esac
    elif [[ "${1:-}" == check-ref-format ]]; then
        "$REAL_GIT" "$@"
    elif [[ "${1:-}" == -C ]]; then
        case "${3:-}" in
            rev-parse) [[ "$TEST_CASE" != workspace-error ]] || return 2; echo true ;;
            remote) if [[ "$TEST_CASE" == remote-warning ]]; then echo https://example.invalid/other; else echo https://example.invalid/repo; fi ;;
            branch) echo other ;;
            diff) [[ "$TEST_CASE" != dirty-warning ]] ;;
            *) mutation "git $*" ;;
        esac
    else
        mutation "git $*"
    fi
}
cmp() { [[ "$TEST_CASE" != vscode-error ]] || return 2; command cmp "$@"; }
defaults() {
    observe "defaults $*"
    case "${1:-}" in
        read-type) [[ "$TEST_CASE" != macos-error ]] || return 2; echo 'Type is string' ;;
        read) echo current ;;
        *) mutation "defaults $*" ;;
    esac
}
SPIES

reset_fixture() {
    rm -rf "$FIXTURE/config/generated" "$TEST_ROOT/home"
    rm -f "$FIXTURE/config/blueprint.conf"
    mkdir -p "$FIXTURE/config/generated/"{vscode,workspace,macos} \
        "$TEST_ROOT/home/.ssh" "$TEST_ROOT/home/Projects/existing/.git" \
        "$TEST_ROOT/home/Library/Application Support/Code/User" "$TEST_ROOT/tmp"
    touch "$TEST_ROOT/home/.ssh/id_test" "$TEST_ROOT/home/.ssh/config" "$TEST_ROOT/home/.zshrc"
    local generated="$FIXTURE/config/generated"
    printf 'present\nabsent\n' > "$generated/brew-packages.conf"
    printf 'example-cask\n' > "$generated/brew-casks.conf"
    printf '111|Present\n222|Absent\n' > "$generated/appstore.conf"
    printf 'publisher.present\npublisher.absent\n' > "$generated/vscode-extensions.conf"
    printf '[user]\n name = Desired\n' > "$generated/git.conf"
    : > "$TEST_ROOT/global.gitconfig"
    printf '{}\n' > "$generated/vscode/settings.json"
    printf '{"current":true}\n' > "$TEST_ROOT/home/Library/Application Support/Code/User/settings.json"
    printf 'Projects|workspace\nNewFolder|workspace\n' > "$generated/workspace/folders.conf"
    local id
    for id in existing absent; do
        cat <<REPO
[$id]
NAME="$id"
PATH="$TEST_ROOT/home/Projects/$id"
REMOTE="https://example.invalid/repo"
DEFAULT_BRANCH="main"
CURRENT_BRANCH="main"
HAS_UNCOMMITTED_CHANGES="false"
HAS_VSCODE_FOLDER="false"
HAS_SETTINGS="false"
HAS_TASKS="false"
HAS_LAUNCH="false"
HAS_EXTENSIONS="false"
REPO
    done > "$generated/workspace/repositories.conf"
    local category
    for category in finder dock keyboard trackpad screenshots; do
        printf 'test.%s|key|string|desired\n' "$category" > "$generated/macos/$category.conf"
    done
}

write_blueprint() {
    {
        echo '[categories]'
        local category
        for category in git-configuration vscode-settings macos-finder macos-dock macos-keyboard macos-trackpad macos-screenshots; do
            printf '%s="true"\n' "$category"
        done
        printf '[homebrew-packages]\npresent\nabsent\n'
        printf '[homebrew-casks]\nexample-cask\n[app-store]\n111\n222\n'
        printf '[vscode-extensions]\npublisher.present\npublisher.absent\n'
        printf '[workspace-folders]\nProjects\nNewFolder\n[git-repositories]\nexisting\nabsent\n'
    } > "$FIXTURE/config/blueprint.conf"
}

run_case() {
    local scenario="$1" expected="$2"
    : > "$TEST_ROOT/mutations"
    : > "$TEST_ROOT/observations"
    find "$TEST_ROOT/home" -type f -exec cksum {} \; | sort > "$TEST_ROOT/before-files"
    find "$TEST_ROOT/home" -print | sort > "$TEST_ROOT/before-paths"
    (
        cd "$FIXTURE" || exit 2
        env HOME="$TEST_ROOT/home" SHELL=/bin/zsh TMPDIR="$TEST_ROOT/tmp" \
            GIT_CONFIG_GLOBAL="$TEST_ROOT/global.gitconfig" GIT_CONFIG_NOSYSTEM=1 \
            BASH_ENV="$TEST_ROOT/spies.sh" TEST_CASE="$scenario" \
            TEST_MODE="${TEST_MODE:---dry-run}" TEST_MUTATIONS="$TEST_ROOT/mutations" TEST_OBSERVATIONS="$TEST_ROOT/observations" \
            /bin/bash ./bootstrap.sh "${TEST_MODE:---dry-run}"
    ) > "$TEST_ROOT/output" 2>&1
    local result=$?
    # Detect target changes even if a future implementation bypasses a spy.
    find "$TEST_ROOT/home" -type f -exec cksum {} \; | sort > "$TEST_ROOT/after-files"
    find "$TEST_ROOT/home" -print | sort > "$TEST_ROOT/after-paths"
    if ! cmp -s "$TEST_ROOT/before-files" "$TEST_ROOT/after-files" ||
       ! cmp -s "$TEST_ROOT/before-paths" "$TEST_ROOT/after-paths"; then
        echo "FAIL: $scenario changed target contents or paths" >&2
        ((TEST_FAILURES++))
    fi
    if [[ $result -ne $expected || -s "$TEST_ROOT/mutations" ]]; then
        echo "FAIL: $scenario expected $expected, got $result" >&2
        cat "$TEST_ROOT/output" "$TEST_ROOT/mutations" >&2
        ((TEST_FAILURES++))
    else
        echo "PASS: $scenario status $result, zero target mutations"
    fi
}
assert_contains() {
    if ! grep -Fq -- "$2" "$1"; then
        echo "FAIL: missing $2 in $1" >&2
        ((TEST_FAILURES++))
    fi
}

reset_fixture
run_case planned 0
# Startup validators must not print generated records before Preview output.
for raw_record in '^present$' '^absent$' '^example-cask$' '^111|Present$' '^publisher.present$'; do
    if grep -Eq "$raw_record" "$TEST_ROOT/output"; then
        echo "FAIL: startup validation printed generated input: $raw_record" >&2
        ((TEST_FAILURES++))
    fi
done
# Full mixed inventory traverses all production domains in stable order.
sed -n 's/.*\(Would .*\)/\1/p' "$TEST_ROOT/output" > "$TEST_ROOT/first-plan"
cat > "$TEST_ROOT/expected-plan" <<PLAN
Would install Homebrew formula: absent
Would install Homebrew cask: example-cask
Would install App Store app: Absent (222)
Would install VS Code extension: publisher.absent
Would configure Git setting: user.name
Would update VS Code settings
Would create workspace folder: $TEST_ROOT/home/NewFolder
Would switch repository branch: existing -> main
Would clone repository: absent
Would change macOS setting: test.finder/key (current -> desired)
Would restart process: Finder
Would change macOS setting: test.dock/key (current -> desired)
Would restart process: Dock
Would change macOS setting: test.keyboard/key (current -> desired)
Would change macOS setting: test.trackpad/key (current -> desired)
Would change macOS setting: test.screenshots/key (current -> desired)
Would create screenshots directory: $TEST_ROOT/home/Screenshots
Would restart process: SystemUIServer
PLAN
if ! cmp -s "$TEST_ROOT/first-plan" "$TEST_ROOT/expected-plan"; then
    echo 'FAIL: domain order or complete plan differs' >&2
    diff -u "$TEST_ROOT/expected-plan" "$TEST_ROOT/first-plan"
    ((TEST_FAILURES++))
fi
for line in 'Modules Inspected : 13' 'Warnings          : 0' 'Errors            : 0'; do
    assert_contains "$TEST_ROOT/output" "$line"
    assert_contains "$FIXTURE/logs/latest.log" "$line"
done
if ! grep -Eq 'Duration +: [0-9]+s' "$TEST_ROOT/output" ||
   ! grep -Eq 'Duration +: [0-9]+s' "$FIXTURE/logs/latest.log"; then
    echo 'FAIL: Preview Duration missing from terminal or logger Summary' >&2
    ((TEST_FAILURES++))
fi
while IFS= read -r line; do assert_contains "$FIXTURE/logs/latest.log" "$line"; done < "$TEST_ROOT/expected-plan"
if grep -Eq 'Installed *:|Skipped *:' "$TEST_ROOT/output" "$FIXTURE/logs/latest.log"; then
    echo 'FAIL: Bootstrap counters in Preview' >&2; ((TEST_FAILURES++))
fi
run_case planned 0
sed -n 's/.*\(Would .*\)/\1/p' "$TEST_ROOT/output" > "$TEST_ROOT/repeat-plan"
cmp -s "$TEST_ROOT/first-plan" "$TEST_ROOT/repeat-plan" || { echo 'FAIL: unstable plan'; ((TEST_FAILURES++)); }

reset_fixture
rm -f "$FIXTURE/config/generated/vscode/settings.json"
run_case mixed-warning 1
grep -Fv 'Would update VS Code settings' "$TEST_ROOT/expected-plan" > "$TEST_ROOT/expected-mixed-plan"
sed -n 's/.*\(Would .*\)/\1/p' "$TEST_ROOT/output" > "$TEST_ROOT/mixed-plan"
if ! cmp -s "$TEST_ROOT/expected-mixed-plan" "$TEST_ROOT/mixed-plan"; then
    echo 'FAIL: mixed warning/planned domain order differs' >&2
    diff -u "$TEST_ROOT/expected-mixed-plan" "$TEST_ROOT/mixed-plan"
    ((TEST_FAILURES++))
fi
assert_contains "$TEST_ROOT/output" 'Warnings          : 1'
assert_contains "$TEST_ROOT/output" 'Errors            : 0'
assert_contains "$FIXTURE/logs/latest.log" 'Warnings          : 1'
assert_contains "$FIXTURE/logs/latest.log" 'Errors            : 0'

for scenario in preflight-error application-error git-error vscode-error workspace-error macos-error dirty-warning remote-warning; do
    reset_fixture
    expected=2
    [[ "$scenario" != *warning ]] || expected=1
    run_case "$scenario" "$expected"
    if [[ "$scenario" != preflight-error && "$scenario" != macos-error ]]; then
        assert_contains "$TEST_ROOT/output" 'Would restart process: SystemUIServer'
    fi
done
reset_fixture
rm -f "$FIXTURE/config/generated/vscode/settings.json"
run_case macos-error 2
assert_contains "$TEST_ROOT/output" 'Warnings          : 1'
assert_contains "$TEST_ROOT/output" 'Errors            : 1'
reset_fixture
rm -rf "$TEST_ROOT/home/.ssh"
run_case core-error 2
assert_contains "$TEST_ROOT/output" 'Would restart process: SystemUIServer'
reset_fixture
rm -f "$FIXTURE/config/generated/vscode/settings.json"
run_case optional-warning 1
assert_contains "$TEST_ROOT/output" 'Would clone repository: absent'
reset_fixture
rmdir "$TEST_ROOT/home/Projects/existing/.git"
run_case non-git-warning 1
reset_fixture
write_blueprint
run_case valid-blueprint 0
printf '\nmissing-repository\n' >> "$FIXTURE/config/blueprint.conf"
run_case stale-blueprint 1
reset_fixture
printf '[broken]\n' > "$FIXTURE/config/blueprint.conf"
run_case malformed-blueprint 2
[[ ! -s "$TEST_ROOT/observations" ]] || { echo 'FAIL: invalid Blueprint reached readers'; ((TEST_FAILURES++)); }
reset_fixture
printf 'bad record\n' >> "$FIXTURE/config/generated/brew-packages.conf"
run_case malformed-input 2
if grep -q '^preflight\|^brew\|^defaults' "$TEST_ROOT/observations"; then
    echo 'FAIL: invalid input reached preflight/domains'; ((TEST_FAILURES++))
fi
reset_fixture
workflow_input=$'n\n\n\n\n\n\n\n\n\n\n\n\n\n\ny\nn'
TEST_MODE=--workflow run_case workflow-save-preview 0 <<< "$workflow_input"
assert_contains "$TEST_ROOT/output" 'Blueprint saved'
assert_contains "$TEST_ROOT/output" 'Modules Inspected'
assert_contains "$TEST_ROOT/output" 'Apply these changes'
cp "$FIXTURE/config/blueprint.conf" "$TEST_ROOT/saved-blueprint"
workflow_input=$'n\n\n\n\n\n\n\n\n\n\n\n\n\n\nn'
TEST_MODE=--workflow run_case workflow-save-cancel 0 <<< "$workflow_input"
cmp -s "$FIXTURE/config/blueprint.conf" "$TEST_ROOT/saved-blueprint" || {
    echo 'FAIL: cancelled selector changed old Blueprint'; ((TEST_FAILURES++));
}
assert_contains "$TEST_ROOT/output" 'Workflow cancelled.'
if grep -q 'Modules Inspected\|Apply these changes' "$TEST_ROOT/output"; then
    echo 'FAIL: cancelled selector reached Preview'; ((TEST_FAILURES++))
fi
reset_fixture
TEST_MODE=--workflow run_case workflow-selector-eof 0 <<< n
assert_contains "$TEST_ROOT/output" 'Workflow cancelled.'
reset_fixture
printf 'bad record\n' >> "$FIXTURE/config/generated/brew-packages.conf"
TEST_MODE=--workflow run_case workflow-invalid-decline 0 <<< n
assert_contains "$TEST_ROOT/output" 'Discovery is required'
reset_fixture
rm "$FIXTURE/config/generated/brew-packages.conf"
TEST_MODE=--workflow run_case workflow-missing-decline 0 <<< n
assert_contains "$TEST_ROOT/output" 'Generated configuration is unavailable'
# An empty selection has no plans; optional settings can still warn.
for preview_status in 0 1; do
    reset_fixture
    {
        echo '[categories]'
        for category in git-configuration vscode-settings macos-finder macos-dock macos-keyboard macos-trackpad macos-screenshots; do
            enabled=false
            [[ "$preview_status" != 1 || "$category" != vscode-settings ]] || enabled=true
            printf '%s="%s"\n' "$category" "$enabled"
        done
        for section in homebrew-packages homebrew-casks app-store vscode-extensions workspace-folders git-repositories; do
            printf '[%s]\n' "$section"
        done
    } > "$FIXTURE/config/blueprint.conf"
    rm "$FIXTURE/config/generated/vscode/settings.json"
    workflow_input=$'n\n\n\n\n\n\n\n\n\n\n\n\n\n\ny\ny'
    TEST_MODE=--workflow run_case "workflow-zero-plans-$preview_status" "$preview_status" <<< "$workflow_input"
    assert_contains "$TEST_ROOT/output" 'No changes to apply'
    assert_contains "$TEST_ROOT/output" 'Workflow finished.'
    if grep -q 'Apply these changes\|Mode    : Bootstrap' "$TEST_ROOT/output"; then
        echo 'FAIL: zero plans reached Bootstrap'; ((TEST_FAILURES++))
    fi
done

# Real CLI + selector: q/Q must never reach Preview or Bootstrap.
for mode in --blueprint --workflow; do
    for existing in yes no; do
        for prompt_type in choice restore edit save; do
            reset_fixture
            if [[ "$existing" == yes ]]; then
                write_blueprint
                cp "$FIXTURE/config/blueprint.conf" "$TEST_ROOT/before-quit"
            fi
            case "$prompt_type" in
                choice) quit_input=q ;;
                restore) quit_input=$'\n\n\n\n\n\nQ' ;;
                edit) quit_input=$'e\n1\nq' ;;
                save) quit_input=$'\n\n\n\n\n\n\n\n\n\n\n\n\nQ' ;;
            esac
            [[ "$mode" != --workflow ]] || quit_input=$'n\n'"$quit_input"
            TEST_MODE="$mode" run_case "$mode-$prompt_type-quit-$existing" 0 <<< "$quit_input"
            assert_contains "$TEST_ROOT/output" 'Blueprint changes cancelled'
            if [[ "$mode" == --workflow ]]; then
                assert_contains "$TEST_ROOT/output" 'Workflow cancelled.'
            fi
            if grep -q 'Modules Inspected\|Apply these changes\|Mode    : Bootstrap' "$TEST_ROOT/output" ||
               grep -Eq '^preflight$|^brew |^defaults ' "$TEST_ROOT/observations"; then
                echo 'FAIL: quit reached later execution'; ((TEST_FAILURES++))
            fi
            if [[ "$existing" == yes ]]; then
                cmp -s "$FIXTURE/config/blueprint.conf" "$TEST_ROOT/before-quit" || {
                    echo 'FAIL: quit changed Blueprint'; ((TEST_FAILURES++));
                }
            elif [[ -e "$FIXTURE/config/blueprint.conf" ]]; then
                echo 'FAIL: quit created Blueprint'; ((TEST_FAILURES++))
            fi
        done
    done
done
[[ $TEST_FAILURES -eq 0 ]] || exit 1
echo 'All production Preview integration tests passed'
