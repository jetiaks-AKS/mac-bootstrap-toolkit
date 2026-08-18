#!/bin/bash

# ==========================================
# Core
# ==========================================

source modules/core/common/common.sh
source modules/core/logger/logger.sh
source modules/core/homebrew/homebrew.sh
source modules/core/git/git.sh
source modules/core/ssh/ssh.sh
source modules/core/terminal/terminal.sh
source modules/core/preflight/preflight.sh
source modules/core/config/config.sh

# ==========================================
# Blueprint
# ==========================================

source modules/blueprint/blueprint.sh
source modules/blueprint/selector.sh

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
# Discovery
# ==========================================

source modules/discovery/discovery.sh
source modules/discovery/homebrew.sh
source modules/discovery/git.sh
source modules/discovery/vscode.sh
source modules/discovery/macos/macos.sh
source modules/discovery/appstore.sh
source modules/discovery/workspace.sh

# ==========================================
# Bootstrap
# ==========================================

source modules/bootstrap/workspace/workspace.sh

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

        --discover)

            MODE="--discover"
            ;;

        --blueprint)

            MODE="--blueprint"
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

  ./bootstrap.sh --discover
      Analyze current Mac and generate Bootstrap configuration

  ./bootstrap.sh --blueprint
      Select what Bootstrap should restore


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

MODE_NAME="Unknown"

case "$MODE" in

    --check)
        MODE_NAME="Check"
        ;;

    --bootstrap)
        MODE_NAME="Bootstrap"
        ;;

    --discover)
        MODE_NAME="Discovery"
        ;;

    --blueprint)
        MODE_NAME="Blueprint"
        ;;

esac

# ==========================================
# Initialize Logger
# ==========================================

init_logger

info "Mode: $MODE_NAME"

if [[ "$VERBOSE" == true ]]; then
    info "Output: Verbose"
fi

echo
echo "=========================================="
echo " $TOOLKIT_NAME"
echo "=========================================="
echo
echo "Version : $TOOLKIT_VERSION"
echo "Mode    : $MODE_NAME"
echo

if [[ "$MODE" == "--blueprint" ]]; then
    blueprint_selector_run
    blueprint_result=$?
    close_logger
    exit "$blueprint_result"
fi


# ==========================================
# Preflight Checks
# ==========================================

run_preflight_checks

if [[ $? -ne 0 ]]; then

    ((ERROR_COUNT++))

    show_summary
    close_logger
    exit 2

fi

# ==========================================
# System Check
# ==========================================

run_module "Homebrew" check_homebrew
run_module "Git" check_git
run_module "SSH" check_ssh
run_module "Terminal" check_terminal


# ==========================================
# Execution
# ==========================================

case "$MODE" in

    --check)

        ;;

    --bootstrap)

        blueprint_result=0

        if blueprint_exists; then
            run_module "Blueprint Validation" blueprint_validate
            blueprint_result=$?
            [[ $blueprint_result -ne 2 ]] && BLUEPRINT_BOOTSTRAP_SUMMARY=true
        fi

        if [[ $blueprint_result -ne 2 ]]; then

            run_module "Workspace" bootstrap_workspace

            echo

            if blueprint_category_enabled git-configuration; then
                run_module "Git Configuration" configure_git
            fi

            run_module "Homebrew Packages" install_brew_packages

            run_module "Homebrew Casks" install_brew_casks

            run_module "App Store" install_appstore_apps

            run_module "VS Code Extensions" install_vscode_extensions

            if blueprint_category_enabled vscode-settings; then
                run_module "VS Code Settings" apply_vscode_settings
            fi

            if blueprint_category_enabled macos-finder ||
               blueprint_category_enabled macos-dock ||
               blueprint_category_enabled macos-keyboard ||
               blueprint_category_enabled macos-trackpad ||
               blueprint_category_enabled macos-screenshots; then
                apply_macos_settings
            fi

        fi

        ;;

    --discover)

        run_discovery

        ;;

esac

show_summary

close_logger

toolkit_exit_code
exit $?
