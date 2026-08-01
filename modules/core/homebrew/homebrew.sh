#!/bin/bash

# ==========================================
# Проверка Homebrew
# ==========================================

is_homebrew_installed() {

    command -v brew >/dev/null 2>&1

}

# ==========================================
# Установка Homebrew
# ==========================================

install_homebrew() {

    info "Устанавливаю Homebrew..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

}

# ==========================================
# Проверка модуля
# ==========================================

check_homebrew() {

    info "Проверяю Homebrew..."

    if is_homebrew_installed; then
        success "Homebrew уже установлен"
        return 0
    fi

    warning "Homebrew не найден"

    read -p "Установить Homebrew? (y/n): " answer

    if [[ "$answer" != "y" ]]; then
        warning "Установка отменена пользователем"
        return 1
    fi

    install_homebrew

    if is_homebrew_installed; then
        success "Homebrew успешно установлен"
        return 0
    fi

    error "Не удалось установить Homebrew"
    return 2

}