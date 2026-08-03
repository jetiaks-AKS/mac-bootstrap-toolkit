#!/bin/bash

# ==========================================
# Check Git
# ==========================================

is_git_installed() {

    command -v git >/dev/null 2>&1

}

# ==========================================
# Module Check
# ==========================================

check_git() {

    info "Checking Git..."

    if is_git_installed; then
        success "Git is already installed"
        return 0
    fi

    error "Git is not installed"

    return 2

}

# ==========================================
# Configure Git
# ==========================================

configure_git() {

    if [[ ! -f "config/git.conf" ]]; then
        error "config/git.conf not found"
        return 2
    fi

    source config/git.conf

    info "Configuring Git..."

    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"
    git config --global pull.rebase "$GIT_PULL_REBASE"
    git config --global core.editor "$GIT_EDITOR"

    success "Git configured successfully"

    return 0

}
