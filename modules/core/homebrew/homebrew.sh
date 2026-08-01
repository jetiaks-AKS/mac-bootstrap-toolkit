check_homebrew() {

    info "Проверяю Homebrew..."

    if command -v brew >/dev/null 2>&1; then
        success "Homebrew уже установлен"
        return 0
    else
        warning "Homebrew не найден"
        return 1
    fi

}