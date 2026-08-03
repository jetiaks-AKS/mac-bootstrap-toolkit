#!/bin/bash

# ==========================================
# Preflight Runner
# ==========================================

run_preflight() {

    local check_function="$1"

    $check_function

    local result=$?

    echo

    return $result

}

# ==========================================
# Run Required Preflight Check
# ==========================================

require_preflight() {

    run_preflight "$1"

    local result=$?

    case $result in

        0)
            ((SUCCESS_COUNT++))
            ;;

        1)
            ((WARNING_COUNT++))
            ;;

        2)
            ((ERROR_COUNT++))
            show_summary
            exit 1
            ;;

    esac

}

# ==========================================
# Internet
# ==========================================

check_internet() {

    info "Checking Internet connection..."

    if ping -c 1 1.1.1.1 >/dev/null 2>&1; then

        success "Internet connection available"
        return 0

    fi

    error "Internet connection unavailable"
    return 2

}

# ==========================================
# Xcode Command Line Tools
# ==========================================

check_xcode() {

    info "Checking Xcode Command Line Tools..."

    if xcode-select -p >/dev/null 2>&1; then

        success "Xcode Command Line Tools are installed"
        return 0

    fi

    error "Xcode Command Line Tools are not installed"
    return 2

}

# ==========================================
# macOS Version
# ==========================================

check_macos() {

    info "Checking macOS version..."

    local current_version
    current_version=$(sw_vers -productVersion | cut -d "." -f1)

    if [[ "$current_version" -ge "$MIN_MACOS_VERSION" ]]; then

        success "macOS version is supported"
        return 0

    fi

    error "Unsupported macOS version"
    return 2

}

# ==========================================
# Administrator Privileges
# ==========================================

check_admin() {

    info "Checking administrator privileges..."

    if sudo -n true >/dev/null 2>&1; then

        success "Administrator privileges available"
        return 0

    fi

    info "Administrator authentication required..."

    if sudo -v; then

        success "Administrator privileges granted"
        return 0

    fi

    error "Failed to obtain administrator privileges"
    return 2

}
