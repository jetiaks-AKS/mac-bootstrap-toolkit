#!/bin/bash

# ==========================================
# Check Terminal
# ==========================================

check_terminal() {

    info "Checking Terminal..."

    if [[ "$SHELL" != */zsh ]]; then
        warning "Shell is not zsh"
        return 1
    fi

    if [[ ! -f "$HOME/.zshrc" ]]; then
        warning ".zshrc not found"
        return 1
    fi

    success "Terminal is configured"

    return 0

}
