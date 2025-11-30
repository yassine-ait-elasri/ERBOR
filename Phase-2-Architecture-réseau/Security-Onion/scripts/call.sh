#!/bin/bash

# ================================
# CONFIGURATION
# ================================
MAIN="/opt/soar/script.sh"
LOG="/var/log/call.log"
PIDFILE="/var/lib/soar/soar.lock"
INTERVAL=10      # <-- change this to 3 or 5 for testing
# ================================

log() {
    echo "$(date +%Y-%m-%dT%H:%M:%S%z) [CALL] $1" | tee -a "$LOG"
}

log "===== call.sh supervisor STARTED ====="
log "Interval is set to $INTERVAL seconds"
log "Main worker script is: $MAIN"
log "Debug logging to: $LOG"
log "========================================"

while true; do
    log "Tick — checking for running worker..."

    # Detect if MAIN is already running
    RUNNING=$(pgrep -f "$MAIN")

    if [ -n "$RUNNING" ]; then
        log "Worker still running. PID(s): $RUNNING"
    else
        log "Worker NOT running — starting now."

        log "--- BEGIN LIVE OUTPUT FROM WORKER ---"

        # Run the worker with full debug output
        bash "$MAIN" 2>&1 | tee -a "$LOG"

        log "--- END WORKER OUTPUT ---"
        log "Worker finished."

        # Cleanup stale lock/pid
        if [ -f "$PIDFILE" ]; then
            log "Found stale lock $PIDFILE — removing it"
            rm -f "$PIDFILE"
        fi

        # Cleanup old mktemp files
        STALE_FILES=$(find /var/lib/soar -maxdepth 1 -type f -name "processed.*" -mmin +2)
        if [ -n "$STALE_FILES" ]; then
            echo "$STALE_FILES" | while read -r f; do
                log "Deleting stale temp: $f"
                rm -f "$f"
            done
        else
            log "No stale temp files to clean."
        fi
    fi

    log "Sleeping for $INTERVAL seconds..."
    sleep "$INTERVAL"
done
