#!/bin/bash

# ==========================================
# Toolkit Statistics
# ==========================================

MODULES_CHECKED=0
INSTALLED_COUNT=0
SKIPPED_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0

# ==========================================
# Module State
# ==========================================

MODULE_CHANGED=false

# ==========================================
# Information Message
# ==========================================

info() {

    echo "[INFO] $1"
    log "[INFO] $1"

}

# ==========================================
# Detail Message (Verbose Mode)
# ==========================================

detail() {

    log "[INFO] $1"

    [[ "$VERBOSE" == true ]] || return 0

    echo "[INFO] $1"

}

# ==========================================
# Action Message
# ==========================================

action() {

    echo "[....] $1"
    log "[....] $1"

}

# ==========================================
# Success Message
# ==========================================

success() {

    echo "[ OK ] $1"
    log "[ OK ] $1"

}

# ==========================================
# Warning Message
# ==========================================

warning() {

    echo "[WARN] $1"
    log "[WARN] $1"

}

# ==========================================
# Error Message
# ==========================================

error() {

    echo "[ERROR] $1"
    log "[ERROR] $1"

}

# ==========================================
# Section Header
# ==========================================

section() {

    echo
    echo "=========================================="
    echo " $1"
    echo "=========================================="

    log ""
    log "=========================================="
    log " $1"
    log "=========================================="

}

# ==========================================
# Run Module
# ==========================================

run_module() {

    local module_name="$1"
    local module_function="$2"

    section "$module_name"

    ((MODULES_CHECKED++))

    MODULE_CHANGED=false

    $module_function

    local result=$?

    if [[ "$MODULE_CHANGED" == true ]]; then
        ((INSTALLED_COUNT++))
    else
        ((SKIPPED_COUNT++))
    fi

    case $result in

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

    ((MODULES_CHECKED++))

    MODULE_CHANGED=false

    $check_function >/dev/null 2>&1

    local result=$?

    case $result in

        0)

            ((SKIPPED_COUNT++))

            success "$module_name already configured"

            return 0
            ;;

        1)

            if $apply_function; then
                MODULE_CHANGED=true
            fi

            $check_function >/dev/null 2>&1

            if [[ $? -eq 0 ]]; then

                ((INSTALLED_COUNT++))

                success "$module_name configured successfully"

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
    else
        error "Bootstrap completed with errors"
    fi

    echo
    log ""

    echo "------------------------------------------"
    log "------------------------------------------"

    echo "Modules Checked : $MODULES_CHECKED"
    echo "Installed       : $INSTALLED_COUNT"
    echo "Skipped         : $SKIPPED_COUNT"
    echo "Warnings        : $WARNING_COUNT"
    echo "Errors          : $ERROR_COUNT"

    log "Modules Checked : $MODULES_CHECKED"
    log "Installed       : $INSTALLED_COUNT"
    log "Skipped         : $SKIPPED_COUNT"
    log "Warnings        : $WARNING_COUNT"
    log "Errors          : $ERROR_COUNT"

    if [[ -n "$START_TIME" ]]; then

        local end_time
        local duration

        end_time=$(date +%s)
        duration=$((end_time - START_TIME))

        echo "------------------------------------------"
        log "------------------------------------------"

        echo "Duration        : ${duration}s"
        log "Duration        : ${duration}s"

    fi

}
