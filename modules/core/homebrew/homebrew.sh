#!/bin/bash

# ==========================================
# Check Homebrew
# ==========================================

is_homebrew_installed() {

    command -v brew >/dev/null 2>&1

}

# ==========================================
# Install Homebrew
# ==========================================

install_homebrew() {

    info "Installing Homebrew..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

}

# ==========================================
# Module Check
# ==========================================

check_homebrew() {

    info "Checking Homebrew..."

    if is_homebrew_installed; then
        success "Homebrew is already installed"
        return 0
    fi

    warning "Homebrew is not installed"

    read -p "Install Homebrew? (y/n): " answer

    if [[ "$answer" != "y" ]]; then
        warning "Installation cancelled by user"
        return 1
    fi

    install_homebrew

    if is_homebrew_installed; then
        success "Homebrew installed successfully"
        return 0
    fi

    error "Failed to install Homebrew"
    return 2

}
