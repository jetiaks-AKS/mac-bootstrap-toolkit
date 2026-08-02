#!/bin/bash

# ==========================================
# Проверка VS Code CLI
# ==========================================

is_code_installed() {

    command -v code >/dev/null 2>&1

}

# ==========================================
# Установка одного расширения
# ==========================================

install_vscode_extension() {

    local extension="$1"

    if grep -Fxq "$extension" <<< "$VSCODE_EXTENSIONS"; then

        info "$extension уже установлено"
        return 0

    fi

    info "Устанавливаю $extension..."

    if code --install-extension "$extension" >/dev/null 2>&1; then

        success "$extension установлено"

    else

        error "Не удалось установить $extension"

    fi

    VSCODE_EXTENSIONS="$(code --list-extensions)"

}

# ==========================================
# Установка расширений VS Code
# ==========================================

install_vscode_extensions() {

    local config_file="config/vscode-extensions.conf"
    local VSCODE_EXTENSIONS

    if [[ ! -f "$config_file" ]]; then

        error "Файл $config_file не найден"
        return 2

    fi

    if ! is_code_installed; then

        warning "Команда 'code' недоступна"
        return 1

    fi

    info "Устанавливаю расширения VS Code..."

    VSCODE_EXTENSIONS="$(code --list-extensions)"

    while IFS= read -r extension || [[ -n "$extension" ]]; do

        [[ -z "$extension" ]] && continue
        [[ "$extension" =~ ^# ]] && continue

        install_vscode_extension "$extension"

    done < "$config_file"

    success "Расширения VS Code готовы"

}