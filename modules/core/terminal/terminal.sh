#!/bin/bash

# ==========================================
# Check Terminal
# ==========================================

check_terminal() {

    if [[ "$SHELL" != */zsh ]]; then
        warning "Shell is not zsh"
        return 1
    fi

    if [[ ! -f "$HOME/.zshrc" ]]; then
        warning ".zshrc not found"
        return 1
    fi

    success "Terminal already configured"

    return 0

}
