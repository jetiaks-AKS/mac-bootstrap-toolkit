#!/bin/bash

# ==========================================
# Проверка каталога SSH
# ==========================================

check_ssh() {

    info "Проверяю SSH..."

    if [[ ! -d "$HOME/.ssh" ]]; then
        error "Каталог ~/.ssh не найден"
        return 2
    fi

    if ! ls "$HOME/.ssh"/id_* >/dev/null 2>&1; then
        warning "SSH-ключи не найдены"
        return 1
    fi

    if [[ ! -f "$HOME/.ssh/config" ]]; then
        warning "Файл config отсутствует"
        return 1
    fi

    success "SSH настроен"

    return 0

}