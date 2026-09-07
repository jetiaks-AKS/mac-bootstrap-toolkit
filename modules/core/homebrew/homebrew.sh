#!/bin/bash

# ==========================================
# Check Homebrew
# ==========================================

homebrew_availability() {

    command -v brew >/dev/null 2>&1

    case $? in
        0) return 0 ;; # Present.
        1) return 1 ;; # Absent.
        *) return 2 ;; # The availability check itself failed.
    esac

}

is_homebrew_installed() {

    homebrew_availability

}

check_homebrew_read_only() {

    homebrew_availability
    local availability_result=$?

    case $availability_result in
        0)
            success "Homebrew already installed"
            return 0
            ;;
        1)
            warning "Homebrew is not installed"
            return 1
            ;;
        *)
            error "Failed to inspect Homebrew availability"
            return 2
            ;;
    esac

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

    homebrew_availability
    local availability_result=$?

    if [[ $availability_result -eq 0 ]]; then
        success "Homebrew already installed"
        return 0
    fi

    if [[ $availability_result -ne 1 ]]; then
        error "Failed to inspect Homebrew availability"
        return 2
    fi

    warning "Homebrew is not installed"

    read -p "Install Homebrew? (y/n): " answer

    if [[ "$answer" != "y" ]]; then
        warning "Installation cancelled by user"
        return 1
    fi

    install_homebrew

    homebrew_availability
    availability_result=$?

    if [[ $availability_result -eq 0 ]]; then
        success "Homebrew installed successfully"
        return 0
    fi

    if [[ $availability_result -ne 1 ]]; then
        error "Failed to inspect Homebrew availability after installation"
        return 2
    fi

    error "Failed to install Homebrew"
    return 2

}
