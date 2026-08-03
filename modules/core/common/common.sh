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

# ==========================================
# Toolkit Summary
# ==========================================

show_summary() {

    section "Summary"

    echo "Success : $SUCCESS_COUNT"
    echo "Warnings: $WARNING_COUNT"
    echo "Errors  : $ERROR_COUNT"

}

}
