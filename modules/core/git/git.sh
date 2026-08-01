#!/bin/bash

# ==========================================
# Проверка Git
# ==========================================

is_git_installed() {

    command -v git >/dev/null 2>&1

}

# ==========================================
# Проверка модуля
# ==========================================

check_git() {

    info "Проверяю Git..."

    if is_git_installed; then
        success "Git уже установлен"
        return 0
    fi

    error "Git не найден"

    return 2

}

# ==========================================
# Настройка Git
# ==========================================

configure_git() {

    if [[ ! -f "config/git.conf" ]]; then
        error "Файл config/git.conf не найден"
        return 2
    fi

    source config/git.conf

    info "Настраиваю Git..."

    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"
    git config --global pull.rebase "$GIT_PULL_REBASE"
    git config --global core.editor "$GIT_EDITOR"

    success "Git успешно настроен"

    return 0

}