#!/bin/bash

# ==========================================
# Настройка VS Code
# ==========================================

apply_vscode_settings() {

    local source_file="settings/vscode/settings.json"
    local target_dir="$HOME/Library/Application Support/Code/User"
    local target_file="$target_dir/settings.json"

    if [[ ! -f "$source_file" ]]; then

        warning "Файл settings/vscode/settings.json не найден"
        return 1

    fi

      mkdir -p "$target_dir"

    if [[ -f "$target_file" ]]; then

    if cmp -s "$source_file" "$target_file"; then

        info "Настройки VS Code уже актуальны"
        return 0

    fi

      info "Создаю резервную копию текущих настроек VS Code..."

      cp "$target_file" "$target_file.bootstrap.bak"

fi

      cp "$source_file" "$target_file"

      success "Настройки VS Code применены"

}
