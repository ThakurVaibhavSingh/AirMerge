#!/bin/bash
# Session logging module — key-event audit trail, one file per run

init_session_log() {

    if [[ -n "$SESSION_LOG" && -f "$SESSION_LOG" ]]; then
        return 0
    fi

    local log_dir="$SCRIPT_DIR/logs"
    mkdir -p "$log_dir"
	chown "$(logname)":"$(logname)" "$log_dir" 2>/dev/null
    SESSION_LOG="${log_dir}/session_$(date +%Y-%m-%d_%H-%M-%S).log"
    : > "$SESSION_LOG"
	chown "$(logname)":"$(logname)" "$SESSION_LOG" 2>/dev/null
    log_event "SESSION" "Session started"
}

log_event() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -z "$SESSION_LOG" || ! -w "$(dirname "$SESSION_LOG")" ]]; then
        init_session_log
    fi
    echo "[$timestamp] [$level] $message" >> "$SESSION_LOG"
}

view_session_log() {
    clear
    if [[ ! -s "$SESSION_LOG" ]]; then
        warn "No log entries yet"
		enter
    else
        banner "Session Log: $SESSION_LOG"
        echo
        cat "$SESSION_LOG"
        log_event "VIEW" "Session log viewed"
    fi
    enter
}

view_session_log_live() {
    if [[ ! -s "$SESSION_LOG" ]]; then
        warn "No log entries yet"
        enter
        return
    fi
    log_event "VIEW" "Live session log started"
    open_terminal "Session Log" "tail -f '$SESSION_LOG'"
}

save_session_state() {
    declare -p INTER INTERFACE ap ch cp sec pac IP GATEWAY SUBNET file ext tools HASHFILE HCFILE \
        2>/dev/null | sed 's/^declare -- /declare -g -- /' > "$STATE_FILE"
    log_event "STATE" "Session state saved"
    info "Session state saved"
	enter
}

load_session_state() {
    if [[ -f "$STATE_FILE" ]]; then
        source "$STATE_FILE"
        log_event "STATE" "Session state loaded"
        info "Previous session loaded"
    else
        warn "No saved session state found"
        log_event "STATE" "No saved session state found"
    fi
    enter
}

