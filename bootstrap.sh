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

run_module "Homebrew" check_homebrew
run_module "Git" check_git
if [[ "$MODE" == "--bootstrap" ]]; then
    configure_git
fi
if [[ "$MODE" == "--bootstrap" ]]; then

    section "Homebrew Packages"
    install_brew_packages

    section "Homebrew Casks"
    install_brew_casks

    section "App Store"
    install_appstore_apps

fi
run_module "SSH" check_ssh
run_module "Terminal" check_terminal

show_summary