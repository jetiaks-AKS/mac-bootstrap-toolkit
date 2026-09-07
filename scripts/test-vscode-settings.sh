#!/bin/bash
set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${1:-}" != --isolated ]]; then
    TEST_ROOT="$(mktemp -d)"
    trap 'rm -rf "$TEST_ROOT"' EXIT
    env HOME="$TEST_ROOT/home" TEST_ROOT="$TEST_ROOT" bash "$0" --isolated
    exit $?
fi

command mkdir -p "$HOME" "$TEST_ROOT/work/config/generated/vscode"
cd "$TEST_ROOT/work" || exit 1
source "$PROJECT_ROOT/modules/vscode/settings.sh"
SOURCE=config/generated/vscode/settings.json
TARGET="$HOME/Library/Application Support/Code/User/settings.json"
CALLS="$TEST_ROOT/calls"
action() { echo "$*"; }
success() { echo "SUCCESS: $*"; }
warning() { echo "WARNING: $*"; }
error() { echo "ERROR: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }
mkdir() {
    echo mkdir >> "$CALLS"
    [[ "$MODE" != mkdir-fail ]] || return 1
    if [[ "$MODE" == mkdir-partial ]]; then
        command mkdir "$HOME/Library"
        return 1
    fi
    command mkdir "$@"
}
cat() {
    [[ "$MODE" != source-read-error || "$1" != "$SOURCE" ]] || return 1
    command cat "$@"
}
cmp() {
    if [[ "$MODE" == cmp-error ]]; then return 2; fi
    if [[ "$COPIED" == true ]]; then
        [[ "$MODE" != verify-error ]] || return 2
        [[ "$MODE" != verify-mismatch ]] || return 1
    fi
    command cmp "$@"
}
cp() {
    echo cp >> "$CALLS"
    if [[ "$2" == "$TARGET" ]]; then
        [[ "$MODE" != backup-fail ]] || { printf partial > "$3"; return 1; }
    else
        [[ "$MODE" != copy-fail ]] || { printf partial > "$3"; return 1; }
    fi
    command cp "$@"
}
mv() {
    echo mv >> "$CALLS"
    [[ "$MODE" != publish-fail ]] || return 1
    command mv "$@" || return $?
    [[ "$3" != "$TARGET" ]] || COPIED=true
    return 0
}
reset_case() {
    command rm -rf "$HOME/Library" "$SOURCE"
    command mkdir -p "$(dirname "$SOURCE")"
    printf '// preserved comment\n{"editor.fontSize":14,}\n' > "$SOURCE"
    MODE=normal
    MODULE_CHANGED=false
    COPIED=false
    : > "$CALLS"
}
run_case() {
    apply_vscode_settings > "$TEST_ROOT/output" 2>&1
    STATUS=$?
    OUTPUT="$(command cat "$TEST_ROOT/output")"
}
expect() {
    [[ "$STATUS" == "$1" && "$MODULE_CHANGED" == "$2" ]] || fail "$3: status=$STATUS changed=$MODULE_CHANGED"
    if [[ "$STATUS" == 2 && "$OUTPUT" == *SUCCESS:* ]]; then fail "$3: false success"; fi
    pass "$3"
}
existing_target() {
    command mkdir -p "$(dirname "$TARGET")"
    printf 'old settings\n' > "$TARGET"
}

for invalid in missing directory unreadable source-read-error; do
    reset_case
    case "$invalid" in
        missing) command rm "$SOURCE" ;;
        directory) command rm "$SOURCE"; command mkdir "$SOURCE" ;;
        unreadable) chmod 000 "$SOURCE" ;;
        source-read-error) MODE=source-read-error ;;
    esac
    run_case
    expected=2
    [[ "$invalid" != missing ]] || expected=1
    expect "$expected" false "source $invalid"
    [[ ! -s "$CALLS" ]] || fail "source $invalid mutated destination"
    [[ "$invalid" != unreadable ]] || chmod 600 "$SOURCE"
done

reset_case
existing_target
command cp "$SOURCE" "$TARGET"
run_case
expect 0 false 'already equal'
[[ ! -s "$CALLS" ]] || fail 'equal settings performed filesystem actions'

reset_case
existing_target
MODE=cmp-error
run_case
expect 2 false 'cmp error blocks mutation'
[[ ! -s "$CALLS" ]] || fail 'cmp error reached Apply'

for scenario in new different mkdir-fail mkdir-partial backup-fail copy-fail copy-fail-new copy-fail-existing-dir verify-mismatch verify-error publish-fail; do
    reset_case
    case "$scenario" in
        new|mkdir-fail|mkdir-partial|copy-fail-new) ;;
        copy-fail-existing-dir) command mkdir -p "$(dirname "$TARGET")" ;;
        *) existing_target ;;
    esac
    MODE="$scenario"
    [[ "$scenario" != copy-fail-new && "$scenario" != copy-fail-existing-dir ]] || MODE=copy-fail
    run_case
    case "$scenario" in
        new|different)
            expect 0 true "$scenario settings copied and verified"
            command cmp -s "$SOURCE" "$TARGET" || fail 'copy lost source bytes'
            MODULE_CHANGED=false
            COPIED=false
            : > "$CALLS"
            run_case
            expect 0 false "$scenario idempotent rerun"
            [[ ! -s "$CALLS" ]] || fail 'rerun performed filesystem actions'
            ;;
        mkdir-fail|backup-fail|publish-fail|copy-fail-existing-dir)
            expect 2 false "$scenario without retained mutation" ;;
        *) expect 2 true "$scenario retains successful directory/backup/settings mutation" ;;
    esac
    if [[ "$scenario" == copy-fail ]]; then
        [[ "$(command cat "$TARGET")" == 'old settings' ]] || fail 'failed copy damaged settings'
        command cmp -s "$TARGET" "$TARGET.bootstrap.bak" || fail 'backup did not preserve old settings'
    fi
    if [[ "$scenario" == backup-fail ]]; then
        [[ ! -e "$TARGET.bootstrap.bak" ]] || fail 'failed backup published partial bytes'
    fi
    [[ -z "$(find "$HOME" -name '*.tmp.*' -print)" ]] || fail 'staging file leaked'
done

# Unsupported destination shapes fail before mutation.
for target_kind in directory dangling-link different-link; do
    reset_case
    command mkdir -p "$(dirname "$TARGET")"
    case "$target_kind" in
        directory) command mkdir "$TARGET" ;;
        dangling-link) ln -s "$TEST_ROOT/nonexistent" "$TARGET" ;;
        different-link)
            printf old > "$TEST_ROOT/link-destination"
            ln -s "$TEST_ROOT/link-destination" "$TARGET"
            ;;
    esac
    run_case
    expect 2 false "target $target_kind blocks Apply"
    [[ ! -s "$CALLS" ]] || fail 'invalid target reached Apply'
done

reset_case
existing_target
printf 'older backup\n' > "$TARGET.bootstrap.bak"
MODE=backup-fail
run_case
expect 2 false 'failed backup preserves existing backup'
[[ "$(command cat "$TARGET.bootstrap.bak")" == 'older backup' ]] || fail 'failed backup replaced old backup'

reset_case
command mkdir -p "$(dirname "$TARGET")"
command cp "$SOURCE" "$TEST_ROOT/equal-link-target"
ln -s "$TEST_ROOT/equal-link-target" "$TARGET"
run_case
expect 0 false 'equal settings symlink remains a no-op'
[[ ! -s "$CALLS" && -L "$TARGET" ]] || fail 'equal symlink was changed'

reset_case
existing_target
chmod 000 "$TARGET"
run_case
expect 2 false 'unreadable target blocks Apply'
[[ ! -s "$CALLS" ]] || fail 'unreadable target reached Apply'
chmod 600 "$TARGET"

echo 'All VS Code settings lifecycle tests passed'
