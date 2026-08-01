check_homebrew() {

    info "Проверяю Homebrew..."

    if command -v brew >/dev/null 2>&1; then
        success "Homebrew уже установлен"
    else
        warning "Homebrew не найден"
    fi

}