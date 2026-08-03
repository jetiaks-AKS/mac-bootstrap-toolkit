#!/bin/bash

# ==========================================
# Core
# ==========================================

source modules/core/common/common.sh
source modules/core/homebrew/homebrew.sh
source modules/core/git/git.sh
source modules/core/ssh/ssh.sh
source modules/core/terminal/terminal.sh

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
# Toolkit Version
# ==========================================

TOOLKIT_VERSION="0.1.0-dev"

# ==========================================
# Режим работы Toolkit
# ==========================================

MODE="${1:---check}"

case "$MODE" in

    --check)

        info "Режим: Проверка"

        ;;

    --bootstrap)

        info "Режим: Bootstrap"

        ;;

    --version)

        echo "Mac Bootstrap Toolkit"
        echo "Version $TOOLKIT_VERSION"
        exit 0

        ;;

    --help)

        cat << EOF

==========================================
 Mac Bootstrap Toolkit
==========================================

Использование:

  ./bootstrap.sh --check
      Проверить систему

  ./bootstrap.sh --bootstrap
      Выполнить настройку Mac

  ./bootstrap.sh --version
      Показать версию Toolkit

  ./bootstrap.sh --help
      Показать эту справку

EOF

        exit 0

        ;;

    *)

        error "Неизвестный режим: $MODE"

        echo
        echo "Используйте:"
        echo "  ./bootstrap.sh --help"

        exit 1

        ;;

esac

echo
echo "=========================================="
echo " Mac Bootstrap Toolkit"
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
# Проверка системы
# ==========================================

run_module "Homebrew" check_homebrew
run_module "Git" check_git
run_module "SSH" check_ssh
run_module "Terminal" check_terminal
check_macos_settings

# ==========================================
# Настройка системы
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
