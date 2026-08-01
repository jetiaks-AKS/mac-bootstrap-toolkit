#!/bin/bash

# ==========================================
# Проверка Terminal
# ==========================================

check_terminal() {

    info "Проверяю Terminal..."

    if [[ "$SHELL" != */zsh ]]; then
        warning "Используется не zsh"
        return 1
    fi

    if [[ ! -f "$HOME/.zshrc" ]]; then
        warning "Файл .zshrc отсутствует"
        return 1
    fi

    success "Terminal готов к работе"

    return 0

}