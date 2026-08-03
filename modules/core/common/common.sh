#!/bin/bash

# ==========================================
# Toolkit Statistics
# ==========================================

SUCCESS_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0

# ==========================================
# Information Message
# ==========================================

info() {
    echo "[INFO] $1"
}

# ==========================================
# Detail Message (Verbose Mode)
# ==========================================

detail() {

    [[ "$VERBOSE" == true ]] || return 0

    info "$1"

}

# ==========================================
# Success Message
# ==========================================

success() {
    echo "[ OK ] $1"
}

# ==========================================
# Warning Message
# ==========================================

warning() {
    echo "[WARN] $1"
}

# ==========================================
# Error Message
# ==========================================

error() {
    echo "[ERROR] $1"
}

# ==========================================
# Section Header
# ==========================================

section() {

    echo
    echo "=========================================="
    echo " $1"
    echo "=========================================="

}

# ==========================================
# Run Module
# ==========================================

run_module() {

    local module_name="$1"
    local module_function="$2"

    section "$module_name"

    $module_function

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
            ;;

    esac

}

# ==========================================
# Run Configuration
# ==========================================

run_configuration() {

    local module_name="$1"
    local check_function="$2"
    local apply_function="$3"

    section "$module_name"

    $check_function

    local result=$?

    case $result in

        0)

            ((SUCCESS_COUNT++))
            return 0
            ;;

        1)

            $apply_function

            $check_function

            if [[ $? -eq 0 ]]; then
                ((SUCCESS_COUNT++))
                return 0
            fi

            error "$module_name configuration failed"
            ((ERROR_COUNT++))
            return 2
            ;;

        2)

            ((ERROR_COUNT++))
            return 2
            ;;

    esac

}

# ==========================================
# Toolkit Summary
# ==========================================

show_summary() {

    section "Summary"

    if [[ $ERROR_COUNT -eq 0 ]]; then

        success "Bootstrap completed successfully"
        echo

    else

        error "Bootstrap completed with errors"
        echo

    fi

    echo "Modules  : $SUCCESS_COUNT"
    echo "Warnings : $WARNING_COUNT"
    echo "Errors   : $ERROR_COUNT"

}
