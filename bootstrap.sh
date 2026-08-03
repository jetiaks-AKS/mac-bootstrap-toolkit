#!/bin/bash

# ==========================================
# Core
# ==========================================

source modules/core/common/common.sh
source modules/core/homebrew/homebrew.sh
source modules/core/git/git.sh
source modules/core/ssh/ssh.sh
source modules/core/terminal/terminal.sh
source modules/core/preflight/preflight.sh

# ==========================================
# Applications
# ==========================================

source modules/apps/brew-packages.sh
source modules/apps/brew-casks.sh
source modules/apps/appstore.sh

# ==========================================
# VS Code
# ==========================================

source modules/vscode/extensions.sh
source modules/vscode/settings.sh

# ==========================================
# macOS Settings
# ==========================================

source modules/settings/macos/macos.sh

# ==========================================
# Toolkit Configuration
# ==========================================

source config/toolkit.conf

# ==========================================
# Toolkit Mode
# ==========================================

MODE="--check"
VERBOSE=false

for arg in "$@"; do

    case "$arg" in

        --check)

            MODE="--check"
            ;;

        --bootstrap)

            MODE="--bootstrap"
            ;;

        -v|--verbose)

            VERBOSE=true
            ;;

        --version)

            echo "$TOOLKIT_NAME"
            echo "Version $TOOLKIT_VERSION"
            exit 0
            ;;

        --help)

            cat << EOF

==========================================
 Mac Bootstrap Toolkit
==========================================

Usage:

  ./bootstrap.sh --check
      Check system configuration

  ./bootstrap.sh --bootstrap
      Bootstrap this Mac

Options:

  -v, --verbose
      Show detailed output

  ./bootstrap.sh --version
      Show Toolkit version

  ./bootstrap.sh --help
      Show this help

EOF

            exit 0
            ;;

        *)

            error "Unknown option: $arg"

            echo
            echo "Use:"
            echo "  ./bootstrap.sh --help"

            exit 1
            ;;

    esac

done

if [[ "$MODE" == "--check" ]]; then
    info "Mode: Check"
else
    info "Mode: Bootstrap"
fi

if [[ "$VERBOSE" == true ]]; then
    info "Output: Verbose"
fi

echo
echo "=========================================="
echo " $TOOLKIT_NAME"
echo "=========================================="
echo
echo "Version : $TOOLKIT_VERSION"

if [[ "$MODE" == "--check" ]]; then
    echo "Mode    : Check"
else
    echo "Mode    : Bootstrap"
fi

echo

# ==========================================
# Preflight Checks
# ==========================================

section "Preflight Checks"

require_preflight check_internet
require_preflight check_xcode
require_preflight check_macos
require_preflight check_admin

# ==========================================
# System Check
# ==========================================

run_module "Homebrew" check_homebrew
run_module "Git" check_git
run_module "SSH" check_ssh
run_module "Terminal" check_terminal


# ==========================================
# Bootstrap
# ==========================================

if [[ "$MODE" == "--bootstrap" ]]; then

    configure_git

    section "Homebrew Packages"
    install_brew_packages

    section "Homebrew Casks"
    install_brew_casks

    section "App Store"
    install_appstore_apps

    section "VS Code Extensions"
    install_vscode_extensions

    section "VS Code Settings"
    apply_vscode_settings

    apply_macos_settings

fi

show_summary
