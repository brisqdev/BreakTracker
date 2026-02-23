#!/usr/bin/env bash
# ============================================================
# BreakTracker Popup Daemon
# Monitors ScreenSaverEngine and shows a summary popup
# when the screensaver exits.
# ============================================================

START_TIME_FILE="/tmp/break_tracker_start.txt"
LOG_FILE="$HOME/.break_tracker.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

screensaver_running() {
    pgrep -x ScreenSaverEngine > /dev/null 2>&1
}

format_duration() {
    local total_secs=$1
    local h=$(( total_secs / 3600 ))
    local m=$(( (total_secs % 3600) / 60 ))
    local s=$(( total_secs % 60 ))

    if [[ $h -gt 0 ]]; then
        printf "%d hour%s, %d minute%s, %d second%s" \
            "$h" "$([[ $h -ne 1 ]] && echo s)" \
            "$m" "$([[ $m -ne 1 ]] && echo s)" \
            "$s" "$([[ $s -ne 1 ]] && echo s)"
    elif [[ $m -gt 0 ]]; then
        printf "%d minute%s, %d second%s" \
            "$m" "$([[ $m -ne 1 ]] && echo s)" \
            "$s" "$([[ $s -ne 1 ]] && echo s)"
    else
        printf "%d second%s" "$s" "$([[ $s -ne 1 ]] && echo s)"
    fi
}

show_break_summary() {
    local raw_start="$1"
    local raw_end="$2"

    # Parse ISO8601 start time written by the screensaver
    local start_epoch
    start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$raw_start" "+%s" 2>/dev/null || \
                  date -d "$raw_start" "+%s" 2>/dev/null)

    local end_epoch
    end_epoch=$(date "+%s")

    local diff=$(( end_epoch - start_epoch ))

    # Human-readable versions
    local start_fmt
    start_fmt=$(date -r "$start_epoch" "+%-I:%M:%S %p" 2>/dev/null || \
                date -d "@$start_epoch" "+%-I:%M:%S %p")
    local end_fmt
    end_fmt=$(date -r "$end_epoch"   "+%-I:%M:%S %p" 2>/dev/null || \
              date -d "@$end_epoch"  "+%-I:%M:%S %p")

    local dur
    dur=$(format_duration "$diff")

    log "Break ended. Start=$start_fmt End=$end_fmt Duration=$dur"

    # AppleScript dialog — appears on top of everything
    osascript <<APPLESCRIPT
tell application "System Events"
    set theDialog to display dialog "☕  Break Summary

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Started:   ${start_fmt}
  Ended:     ${end_fmt}
  Duration:  ${dur}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Welcome back! 👋" ¬
        with title "BreakTracker" ¬
        buttons {"Close", "Log Break"} ¬
        default button "Close" ¬
        with icon note
    set theButton to button returned of theDialog
    return theButton
end tell
APPLESCRIPT
    # If user chose "Log Break" write to a nice log
    if [[ $? -eq 0 ]]; then
        local log_entry
        log_entry="$(date '+%A, %B %-d %Y') | Start: $start_fmt | End: $end_fmt | Duration: $dur"
        echo "$log_entry" >> "$HOME/.break_tracker_log.txt"
    fi
}

# ─────────────────────────────────────────────
# Main loop
# ─────────────────────────────────────────────
log "BreakTracker popup daemon started (PID $$)"

was_running=false
start_iso=""

while true; do
    if screensaver_running; then
        if [[ "$was_running" == "false" ]]; then
            # Screensaver JUST started
            was_running=true
            # Give the screensaver a moment to write the start-time file
            sleep 2
            if [[ -f "$START_TIME_FILE" ]]; then
                start_iso=$(cat "$START_TIME_FILE")
            else
                # Fallback: record current time in ISO8601
                start_iso=$(date -u "+%Y-%m-%dT%H:%M:%SZ")
            fi
            log "Screensaver started. Recorded start: $start_iso"
        fi
    else
        if [[ "$was_running" == "true" ]]; then
            # Screensaver JUST stopped
            was_running=false
            log "Screensaver stopped."
            if [[ -n "$start_iso" ]]; then
                show_break_summary "$start_iso"
                rm -f "$START_TIME_FILE"
                start_iso=""
            fi
        fi
    fi
    sleep 2
done
