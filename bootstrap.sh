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

    *)
        error "Неизвестный режим: $MODE"
        exit 1
        ;;

esac

info "Mac Bootstrap Toolkit"

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
