#!/bin/bash

# ==========================================
# Check Git
# ==========================================

is_git_installed() {

    command -v git >/dev/null 2>&1

}

# ==========================================
# Check Git Configuration
# ==========================================

check_git_configuration() {

    source config/generated/git.conf

    if [[ "$(git config --global user.name)" != "$GIT_USER_NAME" ]]; then
        return 1
    fi

    if [[ "$(git config --global user.email)" != "$GIT_USER_EMAIL" ]]; then
        return 1
    fi

    if [[ "$(git config --global init.defaultBranch)" != "$GIT_DEFAULT_BRANCH" ]]; then
        return 1
    fi

    if [[ "$(git config --global pull.rebase)" != "$GIT_PULL_REBASE" ]]; then
        return 1
    fi

    if [[ "$(git config --global core.editor)" != "$GIT_EDITOR" ]]; then
        return 1
    fi

    return 0

}

# ==========================================
# Module Check
# ==========================================

check_git() {

    if is_git_installed; then
        success "Git already installed"
        return 0
    fi

    error "Git is not installed"

    return 2

}

# ==========================================
# Configure Git
# ==========================================

configure_git() {

    if [[ ! -f "config/generated/git.conf" ]]; then
        error "config/generated/git.conf not found"
        return 2
    fi

    source config/generated/git.conf

    if check_git_configuration; then
        return 0
    fi

    action "Configuring Git..."

    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"
    git config --global pull.rebase "$GIT_PULL_REBASE"
    git config --global core.editor "$GIT_EDITOR"

    success "Git configured successfully"

    return 0

}
