#!/bin/bash

# ==========================================
# Preflight Runner
# ==========================================

run_preflight() {

    local check_function="$1"

    $check_function

    return $?

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
