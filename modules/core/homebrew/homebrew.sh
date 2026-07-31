check_homebrew() {

    info "Проверяю Homebrew..."

    if command -v brew >/dev/null; then
        info "Homebrew уже установлен"
    else
        info "Homebrew не найден"
    fi

}