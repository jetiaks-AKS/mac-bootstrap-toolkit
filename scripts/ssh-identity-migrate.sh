#!/bin/bash
set -u
SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd)" || exit 2
source "$SCRIPT_ROOT/modules/migration/ssh-identities.sh"
migration_main "$@"
