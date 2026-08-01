#!/bin/bash

# ==========================================
# Установка одного приложения App Store
# ==========================================

install_appstore_app() {

    local app_id="$1"
    local app_name="$2"

    if grep -Fq "$app_name" <<< "$MAS_INSTALLED_APPS"; then

        info "$app_name уже установлен"
        return 0

    fi

    info "Устанавливаю $app_name..."

    if mas install "$app_id"; then
        success "$app_name установлен"

    else
        error "Не удалось установить $app_name"

    fi


}

# ==========================================
# Установка приложений App Store
# ==========================================

install_appstore_apps() {

    if ! command -v mas >/dev/null 2>&1; then

        warning "mas не установлен"
        return 1

    fi

    local config_file="config/appstore.conf"

    if [[ ! -f "$config_file" ]]; then
        error "Файл $config_file не найден"
        return 2
    fi

    info "Проверяю установленные приложения..."

    MAS_INSTALLED_APPS="$(mas list)"

    info "Устанавливаю приложения App Store..."

    while IFS='|' read -r app_id app_name || [[ -n "$app_id" ]]; do

        [[ -z "$app_id" ]] && continue
        [[ "$app_id" =~ ^# ]] && continue

        install_appstore_app "$app_id" "$app_name"

    done < "$config_file"

    success "Приложения App Store готовы"

}