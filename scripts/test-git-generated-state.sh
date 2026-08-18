#!/bin/bash

# ==========================================
# Git Generated-State Safety Harness
# ==========================================

set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT INT TERM

REAL_GIT="$(command -v git)"
export HOME="$TEST_ROOT/home"
export GIT_CONFIG_GLOBAL="$TEST_ROOT/global.gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export TMPDIR="$TEST_ROOT/tmp"

TEST_FAILURES=0
VERBOSE=false
GIT_AVAILABLE=true
GIT_TEST_MODE=normal
GIT_FAILURE_KEY=""
SUCCESS_MESSAGES=""
ERROR_MESSAGES=""

mkdir -p "$HOME" "$TMPDIR"

source "$PROJECT_ROOT/modules/core/common/common.sh"
source "$PROJECT_ROOT/modules/discovery/discovery.sh"

log() { :; }
action() { :; }
detail() { :; }
success() {
    SUCCESS_MESSAGES="${SUCCESS_MESSAGES}${SUCCESS_MESSAGES:+
}$1"
}
error() {
    ERROR_MESSAGES="${ERROR_MESSAGES}${ERROR_MESSAGES:+
}$1"
}
warning() { :; }

command() {
    if [[ "${1:-}" == "-v" && "${2:-}" == "git" && "$GIT_AVAILABLE" != true ]]; then
        return 1
    fi
    builtin command "$@"
}

git() {
    if [[ "$GIT_TEST_MODE" == read-failure &&
          "$*" == "config --global --null --get-all $GIT_FAILURE_KEY" ]]; then
        return 2
    fi

    if [[ "$GIT_TEST_MODE" == current-read-failure &&
          "$*" == "config --global --null --get-all $GIT_FAILURE_KEY" ]]; then
        return 2
    fi

    if [[ "$GIT_TEST_MODE" == write-failure &&
          "${1:-}" == config && "${2:-}" == --global &&
          "${3:-}" == "$GIT_FAILURE_KEY" ]]; then
        return 2
    fi

    if [[ "$GIT_TEST_MODE" == unset-failure &&
          "$*" == "config --global --unset-all $GIT_FAILURE_KEY" ]]; then
        return 2
    fi

    if [[ "$GIT_TEST_MODE" == ignore-write &&
          "${1:-}" == config && "${2:-}" == --global &&
          "${3:-}" == "$GIT_FAILURE_KEY" ]]; then
        return 0
    fi

    "$REAL_GIT" "$@"
}

source "$PROJECT_ROOT/modules/discovery/git.sh"
source "$PROJECT_ROOT/modules/core/git/git.sh"

pass() { echo "PASS: $1"; }
fail() {
    echo "FAIL: $1"
    ((TEST_FAILURES++))
}

reset_fixture() {
    rm -rf "$TEST_ROOT/config" "$TMPDIR"
    rm -f "$GIT_CONFIG_GLOBAL"
    mkdir -p "$TMPDIR"
    GIT_AVAILABLE=true
    GIT_TEST_MODE=normal
    GIT_FAILURE_KEY=""
    SUCCESS_MESSAGES=""
    ERROR_MESSAGES=""
}

reset_counters() {
    MODULES_CHECKED=0
    INSTALLED_COUNT=0
    SKIPPED_COUNT=0
    WARNING_COUNT=0
    ERROR_COUNT=0
}

restore_serializer() {
    source "$PROJECT_ROOT/modules/discovery/git.sh"
}

generated_temporary_files() {
    find config/generated -type f -name 'git.conf.tmp.*' -print 2>/dev/null
}

temporary_files() {
    find "$TMPDIR" -mindepth 1 -print 2>/dev/null
}

seed_all_global_values() {
    "$REAL_GIT" config --global user.name 'Test User'
    "$REAL_GIT" config --global user.email 'test@example.com'
    "$REAL_GIT" config --global init.defaultBranch main
    "$REAL_GIT" config --global pull.rebase false
    "$REAL_GIT" config --global core.editor 'code --wait'
}

write_generated_value() {
    local key="$1"
    local value="$2"
    mkdir -p config/generated
    touch config/generated/git.conf
    "$REAL_GIT" config --file config/generated/git.conf "$key" "$value"
}

cd "$TEST_ROOT" || exit 1

# ==========================================
# Discovery
# ==========================================

reset_fixture
seed_all_global_values
discover_git >/dev/null
discovery_status=$?
generated_keys="$("$REAL_GIT" config --file config/generated/git.conf --no-includes --name-only --list)"
expected_keys=$'user.name\nuser.email\ninit.defaultbranch\npull.rebase\ncore.editor'
if [[ $discovery_status -eq 0 && "$generated_keys" == "$expected_keys" &&
      "$("$REAL_GIT" config --file config/generated/git.conf --get user.name)" == 'Test User' &&
      "$SUCCESS_MESSAGES" == *'Git configuration exported'* ]]; then
    pass "Git Discovery publishes five supported keys in deterministic order"
else
    fail "Git Discovery native format, ordering, or success changed"
fi

reset_fixture
"$REAL_GIT" config --global user.name 'Only User'
discover_git >/dev/null
partial_status=$?
partial_keys="$("$REAL_GIT" config --file config/generated/git.conf --name-only --list)"
if [[ $partial_status -eq 0 && "$partial_keys" == 'user.name' ]]; then
    pass "Git Discovery omits unset supported keys"
else
    fail "Git Discovery did not preserve partially unset state"
fi

reset_fixture
discover_git >/dev/null
empty_status=$?
if [[ $empty_status -eq 0 && -f config/generated/git.conf &&
      ! -s config/generated/git.conf ]]; then
    pass "all-unset Git observation publishes a valid empty file"
else
    fail "all-unset Git observation is not a successful empty state"
fi

reset_fixture
"$REAL_GIT" config --global user.email ''
discover_git >/dev/null
load_git_configuration >/dev/null
if [[ "${GIT_CONFIGURATION_SET[0]}" == false &&
      "${GIT_CONFIGURATION_SET[1]}" == true &&
      -z "${GIT_CONFIGURATION_VALUES[1]}" ]]; then
    pass "configured empty Git value remains distinct from unset"
else
    fail "configured empty and unset Git values were collapsed"
fi

reset_fixture
marker_file="$TEST_ROOT/shell-content-executed"
literal_value='Name "quoted" \ path $HOME `printf marker` $(touch '
literal_value+="$marker_file"
literal_value+=')'
literal_value+=$'\tTabbed\nNew line\rCarriage return'
"$REAL_GIT" config --global user.name "$literal_value"
discover_git >/dev/null
safe_discovery_status=$?
load_git_configuration >/dev/null
safe_load_status=$?
if [[ $safe_discovery_status -eq 0 && $safe_load_status -eq 0 &&
      "${GIT_CONFIGURATION_VALUES[0]}" == "$literal_value" &&
      ! -e "$marker_file" ]]; then
    pass "native Git format round-trips shell-looking and control-character data safely"
else
    fail "safe Git literal round-trip changed data or executed shell content"
fi

reset_fixture
GIT_AVAILABLE=false
mkdir -p config/generated
printf 'previous\n' > config/generated/git.conf
before_checksum="$(cksum config/generated/git.conf)"
discover_git >/dev/null
unavailable_status=$?
after_checksum="$(cksum config/generated/git.conf)"
if [[ $unavailable_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$ERROR_MESSAGES" == *'Git is not installed'* && -z "$SUCCESS_MESSAGES" ]]; then
    pass "missing Git returns 2 and preserves generated state"
else
    fail "missing Git changed generated state or reported success"
fi

reset_fixture
seed_all_global_values
GIT_TEST_MODE=read-failure
GIT_FAILURE_KEY=pull.rebase
mkdir -p config/generated
printf 'previous\n' > config/generated/git.conf
before_checksum="$(cksum config/generated/git.conf)"
discover_git >/dev/null
read_failure_status=$?
after_checksum="$(cksum config/generated/git.conf)"
if [[ $read_failure_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$ERROR_MESSAGES" == *'Failed to read global Git configuration: pull.rebase'* &&
      -z "$SUCCESS_MESSAGES" ]]; then
    pass "Git key-read failure preserves previous generated state"
else
    fail "Git key-read failure was masked or destructive"
fi

reset_fixture
"$REAL_GIT" config --global --add user.name First
"$REAL_GIT" config --global --add user.name Second
mkdir -p config/generated
printf 'previous\n' > config/generated/git.conf
before_checksum="$(cksum config/generated/git.conf)"
discover_git >/dev/null
multiple_status=$?
after_checksum="$(cksum config/generated/git.conf)"
if [[ $multiple_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$ERROR_MESSAGES" == *'Multiple global Git values found for user.name'* ]]; then
    pass "multiple global Git values block publication"
else
    fail "multiple global Git values were not rejected safely"
fi

reset_fixture
seed_all_global_values
mkdir -p config/generated
printf 'previous\n' > config/generated/git.conf
before_checksum="$(cksum config/generated/git.conf)"
serialize_git_configuration() { return 2; }
discover_git >/dev/null
serialization_status=$?
after_checksum="$(cksum config/generated/git.conf)"
restore_serializer
if [[ $serialization_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      "$ERROR_MESSAGES" == *'Failed to publish Git configuration'* &&
      -z "$SUCCESS_MESSAGES" && -z "$(generated_temporary_files)" ]]; then
    pass "Git serialization failure preserves state and cleans publication temp"
else
    fail "Git serialization failure changed state or leaked publication temp"
fi

reset_fixture
seed_all_global_values
mkdir -p config/generated
printf 'previous\n' > config/generated/git.conf
before_checksum="$(cksum config/generated/git.conf)"
serialize_git_configuration() {
    printf '[broken\n' > "$1"
    "$REAL_GIT" config --file "$1" --no-includes --list >/dev/null 2>&1 || return 2
}
discover_git >/dev/null
validation_status=$?
after_checksum="$(cksum config/generated/git.conf)"
restore_serializer
if [[ $validation_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      -z "$(generated_temporary_files)" ]]; then
    pass "Git serializer validation failure blocks publication"
else
    fail "Git serializer validation failure replaced state or leaked temp"
fi

reset_fixture
seed_all_global_values
mkdir -p config/generated
printf 'previous\n' > config/generated/git.conf
before_checksum="$(cksum config/generated/git.conf)"
mv() { return 1; }
discover_git >/dev/null
publication_status=$?
unset -f mv
after_checksum="$(cksum config/generated/git.conf)"
if [[ $publication_status -eq 2 && "$before_checksum" == "$after_checksum" &&
      -z "$SUCCESS_MESSAGES" && -z "$(generated_temporary_files)" &&
      -z "$(temporary_files)" ]]; then
    pass "Git publication failure preserves state and cleans all temporary files"
else
    fail "Git publication failure changed state or leaked temporary files"
fi

for lifecycle_case in success error; do
    reset_fixture
    reset_counters
    if [[ "$lifecycle_case" == success ]]; then
        seed_all_global_values
        expected_status=0
        expected_errors=0
    else
        seed_all_global_values
        GIT_TEST_MODE=read-failure
        GIT_FAILURE_KEY=user.email
        expected_status=2
        expected_errors=1
    fi
    run_module "Git Discovery" discover_git >/dev/null
    lifecycle_status=$?
    if [[ $lifecycle_status -eq $expected_status &&
          $MODULES_CHECKED -eq 1 && $ERROR_COUNT -eq $expected_errors ]]; then
        pass "Git Discovery run_module propagates $expected_status"
    else
        fail "Git Discovery run_module failed to propagate $expected_status"
    fi
done

# ==========================================
# Consumer Validation
# ==========================================

reset_fixture
seed_all_global_values
mkdir -p config/generated
cp "$GIT_CONFIG_GLOBAL" config/generated/git.conf
load_git_configuration >/dev/null
[[ $? -eq 0 ]] && pass "consumer accepts ordinary native Git configuration" ||
    fail "consumer rejected ordinary native Git configuration"

reset_fixture
mkdir -p config/generated
: > config/generated/git.conf
load_git_configuration >/dev/null
[[ $? -eq 0 ]] && pass "consumer accepts valid empty Git configuration" ||
    fail "consumer rejected valid empty Git configuration"

reset_fixture
mkdir -p config/generated
printf '[broken\n' > config/generated/git.conf
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects malformed Git syntax" ||
    fail "consumer accepted malformed Git syntax"

reset_fixture
write_generated_value alias.unsafe '!printf harmless'
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects unknown Git keys" ||
    fail "consumer accepted unknown Git key"

reset_fixture
write_generated_value include.path "$TEST_ROOT/include.conf"
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects Git include keys" ||
    fail "consumer accepted Git include key"

reset_fixture
mkdir -p config/generated
{
    echo '[includeIf "gitdir:~/Projects/"]'
    echo "    path = $TEST_ROOT/include.conf"
} > config/generated/git.conf
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects Git conditional include keys" ||
    fail "consumer accepted Git conditional include key"

reset_fixture
write_generated_value user.name First
"$REAL_GIT" config --file config/generated/git.conf --add user.name Second
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects duplicate supported keys" ||
    fail "consumer accepted duplicate supported key"

reset_fixture
mkdir -p config/generated
printf 'GIT_USER_NAME="Old User"\n' > config/generated/git.conf
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects old executable assignment format" ||
    fail "consumer accepted old executable assignment format"

reset_fixture
write_generated_value pull.rebase malformed
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects invalid pull.rebase" ||
    fail "consumer accepted invalid pull.rebase"

reset_fixture
write_generated_value init.defaultBranch ''
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects invalid empty default branch" ||
    fail "consumer accepted invalid empty default branch"

reset_fixture
write_generated_value user.name ''
load_git_configuration >/dev/null
if [[ $? -eq 0 && "${GIT_CONFIGURATION_SET[0]}" == true &&
      -z "${GIT_CONFIGURATION_VALUES[0]}" ]]; then
    pass "consumer accepts explicitly empty arbitrary string"
else
    fail "consumer lost explicitly empty arbitrary string"
fi

reset_fixture
load_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "consumer rejects missing generated Git file" ||
    fail "consumer accepted missing generated Git file"

reset_fixture
write_generated_value user.name User
chmod 000 config/generated/git.conf
load_git_configuration >/dev/null
unreadable_status=$?
chmod 600 config/generated/git.conf
if [[ $unreadable_status -eq 2 ]]; then
    pass "consumer rejects unreadable generated Git file"
else
    fail "consumer accepted unreadable generated Git file"
fi

# ==========================================
# Check / Apply / Verify
# ==========================================

reset_fixture
seed_all_global_values
mkdir -p config/generated
cp "$GIT_CONFIG_GLOBAL" config/generated/git.conf
check_git_configuration >/dev/null
[[ $? -eq 0 ]] && pass "configured values already matching are satisfied" ||
    fail "matching configured values were not satisfied"

reset_fixture
mkdir -p config/generated
: > config/generated/git.conf
check_git_configuration >/dev/null
[[ $? -eq 0 ]] && pass "matching unset values are satisfied" ||
    fail "matching unset values were not satisfied"

reset_fixture
"$REAL_GIT" config --global user.name Old
write_generated_value user.name New
configure_git >/dev/null
changed_status=$?
changed_value="$("$REAL_GIT" config --global --get user.name)"
if [[ $changed_status -eq 0 && "$changed_value" == New &&
      "$SUCCESS_MESSAGES" == *'Git configured successfully'* ]]; then
    pass "configured value change applies and verifies"
else
    fail "configured value change did not apply and verify"
fi

reset_fixture
"$REAL_GIT" config --global user.name Existing
mkdir -p config/generated
: > config/generated/git.conf
configure_git >/dev/null
unset_status=$?
"$REAL_GIT" config --global --get user.name >/dev/null 2>&1
remaining_status=$?
if [[ $unset_status -eq 0 && $remaining_status -eq 1 ]]; then
    pass "desired unset removes current global Git key"
else
    fail "desired unset did not remove current global Git key"
fi

reset_fixture
write_generated_value user.name ''
GIT_TEST_MODE=current-read-failure
GIT_FAILURE_KEY=user.name
check_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "current Git read failure is not treated as empty match" ||
    fail "current Git read failure was treated as matching"

reset_fixture
write_generated_value user.name Second
"$REAL_GIT" config --global --add user.name First
"$REAL_GIT" config --global --add user.name Second
check_git_configuration >/dev/null
[[ $? -eq 2 ]] && pass "multiple current global values are a check failure" ||
    fail "multiple current global values were treated as a single value"

reset_fixture
write_generated_value user.name New
GIT_TEST_MODE=write-failure
GIT_FAILURE_KEY=user.name
configure_git >/dev/null
if [[ $? -eq 2 && "$SUCCESS_MESSAGES" != *'configured successfully'* ]]; then
    pass "Git configured-value write failure returns 2 without success"
else
    fail "Git configured-value write failure was masked"
fi

reset_fixture
"$REAL_GIT" config --global user.name Existing
mkdir -p config/generated
: > config/generated/git.conf
GIT_TEST_MODE=unset-failure
GIT_FAILURE_KEY=user.name
configure_git >/dev/null
if [[ $? -eq 2 && "$SUCCESS_MESSAGES" != *'configured successfully'* ]]; then
    pass "Git unset failure returns 2 without success"
else
    fail "Git unset failure was masked"
fi

reset_fixture
"$REAL_GIT" config --global user.name Old
write_generated_value user.name New
GIT_TEST_MODE=ignore-write
GIT_FAILURE_KEY=user.name
configure_git >/dev/null
if [[ $? -eq 2 && "$ERROR_MESSAGES" == *'Git configuration verification failed'* &&
      "$SUCCESS_MESSAGES" != *'configured successfully'* ]]; then
    pass "post-apply mismatch returns verification error 2"
else
    fail "post-apply mismatch was not detected"
fi

if [[ $TEST_FAILURES -ne 0 ]]; then
    echo
    echo "$TEST_FAILURES Git generated-state test(s) failed"
    exit 1
fi

echo
echo "All Git generated-state tests passed"
