#!/bin/bash

# ==========================================
# Check SSH
# ==========================================

check_ssh() {

    if [[ ! -d "$HOME" || ! -r "$HOME" || ! -x "$HOME" ]]; then
        error "Failed to inspect SSH HOME"
        return 2
    fi
    if [[ ! -e "$HOME/.ssh" && ! -L "$HOME/.ssh" ]]; then
        warning "SSH directory is absent; selected SSH state can be restored"
        return 1
    fi
    if [[ ! -d "$HOME/.ssh" || ! -r "$HOME/.ssh" || ! -x "$HOME/.ssh" ]]; then
        error "Failed to inspect SSH directory"
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
