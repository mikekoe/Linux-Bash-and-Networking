#!/usr/bin/env bash
# logger.sh - Shared logging helper. SOURCE this file; do not execute it.
#
# Usage in a script:
#   source "$SCRIPT_DIR/logger.sh"
#   log_init "$@"            # logs the start + installs an exit trap
#   log INFO "something happened"
#
# Log location (first match wins):
#   1. $LOG_DIR, if set in the environment
#   2. <git repository root>/logs   (when this file lives inside a git repo)
#   3. <folder of this file>/logs
#
# All scripts append to <log dir>/scripts.log, one line per event:
#   YYYY-MM-DD HH:MM:SS +ZZZZ [LEVEL] [script-name] [PID] description

LOGGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${LOG_DIR:-}" ]; then
    REPO_ROOT="$(git -C "$LOGGER_DIR" rev-parse --show-toplevel 2>/dev/null)"
    if [ -n "$REPO_ROOT" ]; then
        LOG_DIR="$REPO_ROOT/logs"
    else
        LOG_DIR="$LOGGER_DIR/logs"
    fi
fi
LOG_FILE="${LOG_FILE:-$LOG_DIR/scripts.log}"
LOG_SCRIPT="$(basename "$0")"
LOG_ENABLED=1

if ! mkdir -p "$LOG_DIR" 2>/dev/null || ! touch "$LOG_FILE" 2>/dev/null; then
    echo "Warning: cannot write to $LOG_DIR; logging disabled." >&2
    LOG_ENABLED=0
fi

# log LEVEL "description"   (LEVEL: INFO | WARN | ERROR)
log() {
    [ "$LOG_ENABLED" -eq 1 ] || return 0
    printf '%s [%s] [%s] [%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S %z')" "$1" "$LOG_SCRIPT" "$$" "$2" \
        >> "$LOG_FILE" 2>/dev/null
}

log_exit_handler() {
    local rc=$?
    case "$rc" in
        0) log INFO  "Finished successfully (exit code 0)" ;;
        1) log WARN  "Finished: one or more checks failed (exit code 1)" ;;
        2) log ERROR "Finished: invalid input (exit code 2)" ;;
        *) log ERROR "Finished with unexpected exit code $rc" ;;
    esac
}

# log_init "$@"  - record the start of a run and register the exit logger
log_init() {
    trap log_exit_handler EXIT
    log INFO "Started on $(uname -s) as user '$(whoami)' in '$(pwd)' with $# argument(s): $*"
}
