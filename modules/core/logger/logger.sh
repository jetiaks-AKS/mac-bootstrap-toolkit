#!/bin/bash

# ==========================================
# Logger
# ==========================================

LOG_DIR="logs"
LOG_HISTORY_DIR="$LOG_DIR/history"
LOG_FILE=""
LATEST_LOG="$LOG_DIR/latest.log"

START_TIME=0

# ==========================================
# Initialize Logger
# ==========================================

init_logger() {

    mkdir -p "$LOG_HISTORY_DIR"

    local timestamp
    timestamp="$(date +"%Y-%m-%d_%H-%M-%S")"

    LOG_FILE="$LOG_HISTORY_DIR/bootstrap-$timestamp.log"

    touch "$LOG_FILE"

    START_TIME=$(date +%s)

    log "=========================================="
    log " Mac Bootstrap Toolkit"
    log "=========================================="
    log ""
    log "Version  : $TOOLKIT_VERSION"

    if [[ "$MODE" == "--bootstrap" ]]; then
    log "Mode     : Bootstrap"
    else
    log "Mode     : Check"
    fi

    if [[ "$VERBOSE" == true ]]; then
    log "Verbose  : Yes"
    else
    log "Verbose  : No"
    fi

    log ""
    log "Started  : $(date '+%Y-%m-%d %H:%M:%S')"
    log ""
    log "=========================================="

}

# ==========================================
# Write Message To Log
# ==========================================

log() {

    [[ -n "$LOG_FILE" ]] || return 0

    echo "$1" >> "$LOG_FILE"

}

# ==========================================
# Finalize Logger
# ==========================================

close_logger() {

    local end_time
    local duration

    end_time=$(date +%s)
    duration=$((end_time - START_TIME))

    log ""
    log "Finished : $(date '+%Y-%m-%d %H:%M:%S')"
    log "Duration : ${duration}s"
    log ""
    log "=========================================="

    cp "$LOG_FILE" "$LATEST_LOG"

}
