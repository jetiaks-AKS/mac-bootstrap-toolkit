#!/bin/bash

# ==========================================
# Check SSH
# ==========================================

check_ssh() {

    if [[ ! -d "$HOME/.ssh" ]]; then
        error "~/.ssh directory not found"
        return 2
    fi

    if ! ls "$HOME/.ssh"/id_* >/dev/null 2>&1; then
        warning "SSH keys not found"
        return 1
    fi

    if [[ ! -f "$HOME/.ssh/config" ]]; then
        warning "SSH config not found"
        return 1
    fi

    success "SSH already configured"

    return 0

}
