#!/bin/bash

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
FIXTURE="$TEST_ROOT/toolkit"
INSTALL_DIR="$TEST_ROOT/bin"
TEST_FAILURES=0

trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

mkdir -p "$FIXTURE/bin" "$FIXTURE/scripts" "$INSTALL_DIR" "$TEST_ROOT/outside"
cp "$PROJECT_ROOT/bin/bs" "$FIXTURE/bin/bs"
cp "$PROJECT_ROOT/scripts/install-bs.sh" "$FIXTURE/scripts/install-bs.sh"
chmod +x "$FIXTURE/bin/bs" "$FIXTURE/scripts/install-bs.sh"

cat > "$FIXTURE/bootstrap.sh" <<'STUB'
#!/bin/bash
printf '%s|%s\n' "$PWD" "$*" >> "$BS_TEST_DISPATCH"
exit "${BS_TEST_STATUS:-0}"
STUB
chmod +x "$FIXTURE/bootstrap.sh"

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; ((TEST_FAILURES++)); }

run_bs() {
    : > "$TEST_ROOT/dispatch"
    (
        cd "$TEST_ROOT/outside" || exit 2
        BS_TEST_DISPATCH="$TEST_ROOT/dispatch" BS_TEST_STATUS="${BS_TEST_STATUS:-0}" \
            "$FIXTURE/bin/bs" "$@"
    ) > "$TEST_ROOT/output" 2>&1
    BS_STATUS=$?
}

for help_args in "" help --help -h; do
    if [[ -n "$help_args" ]]; then
        run_bs "$help_args"
    else
        run_bs
    fi
    if [[ $BS_STATUS -eq 0 && ! -s "$TEST_ROOT/dispatch" ]] &&
       grep -q 'Usage: bs <command>' "$TEST_ROOT/output"; then
        pass "help form '${help_args:-no arguments}'"
    else
        fail "help form '${help_args:-no arguments}'"
    fi
done

while IFS='|' read -r command mode; do
    run_bs "$command"
    expected="$FIXTURE|$mode"
    if [[ $BS_STATUS -eq 0 && "$(cat "$TEST_ROOT/dispatch")" == "$expected" ]]; then
        pass "$command maps to $mode from outside the repository"
    else
        fail "$command mapping or working directory"
    fi
done <<'MAPPINGS'
workflow|--workflow
discover|--discover
blueprint|--blueprint
preview|--dry-run
bootstrap|--bootstrap
check|--check
MAPPINGS

run_bs unknown
if [[ $BS_STATUS -ne 0 && ! -s "$TEST_ROOT/dispatch" ]] &&
   grep -q 'unknown command' "$TEST_ROOT/output"; then
    pass "unknown command is rejected without dispatch"
else
    fail "unknown command behavior"
fi

BS_TEST_STATUS=2 run_bs preview
[[ $BS_STATUS -eq 2 ]] && pass "production exit status is preserved" ||
    fail "production exit status was changed"

PATH="$INSTALL_DIR:/usr/bin:/bin" BS_INSTALL_DIR="$INSTALL_DIR" \
    "$FIXTURE/scripts/install-bs.sh" > "$TEST_ROOT/install-output" 2>&1
install_status=$?
PATH="$INSTALL_DIR:/usr/bin:/bin" BS_INSTALL_DIR="$INSTALL_DIR" \
    "$FIXTURE/scripts/install-bs.sh" >> "$TEST_ROOT/install-output" 2>&1
repeat_status=$?
if [[ $install_status -eq 0 && $repeat_status -eq 0 && -L "$INSTALL_DIR/bs" &&
      "$(readlink "$INSTALL_DIR/bs")" == "$FIXTURE/bin/bs" ]]; then
    pass "PATH installation is idempotent"
else
    fail "PATH installation idempotence"
fi

rm "$INSTALL_DIR/bs"
mkdir "$TEST_ROOT/other-bin"
ln -s ../toolkit/bin/bs "$TEST_ROOT/other-bin/bs"
PATH="$TEST_ROOT/other-bin:$INSTALL_DIR:/usr/bin:/bin" \
    BS_INSTALL_DIR="$INSTALL_DIR" "$FIXTURE/scripts/install-bs.sh" \
    > "$TEST_ROOT/existing-correct-output" 2>&1
correct_status=$?
if [[ $correct_status -eq 0 && ! -e "$INSTALL_DIR/bs" ]] &&
   grep -q 'already available' "$TEST_ROOT/existing-correct-output"; then
    pass "existing correct PATH symlink is accepted"
else
    fail "existing correct PATH symlink handling"
fi

rm "$TEST_ROOT/other-bin/bs"
printf '#!/bin/bash\n' > "$INSTALL_DIR/bs"
chmod +x "$INSTALL_DIR/bs"
PATH="$INSTALL_DIR:/usr/bin:/bin" BS_INSTALL_DIR="$INSTALL_DIR" \
    "$FIXTURE/scripts/install-bs.sh" > "$TEST_ROOT/conflict-output" 2>&1
conflict_status=$?
if [[ $conflict_status -ne 0 && ! -L "$INSTALL_DIR/bs" ]] &&
   grep -q 'refusing to replace existing file' "$TEST_ROOT/conflict-output"; then
    pass "existing unrelated bs file is preserved"
else
    fail "existing bs conflict behavior"
fi

[[ $TEST_FAILURES -eq 0 ]] || exit 1
printf 'All bs launcher tests passed\n'
