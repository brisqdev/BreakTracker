#!/usr/bin/env bash
# BreakTracker – Uninstaller

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

echo -e "${RED}Uninstalling BreakTracker...${NC}"

PLIST="$HOME/Library/LaunchAgents/com.breaktracker.popup.plist"
if [[ -f "$PLIST" ]]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    echo -e "${GREEN}✔  LaunchAgent removed${NC}"
fi

SAVER="$HOME/Library/Screen Savers/BreakTracker.saver"
[[ -d "$SAVER" ]] && { rm -rf "$SAVER"; echo -e "${GREEN}✔  Screensaver removed${NC}"; }

DAEMON="$HOME/Library/Scripts/BreakTracker/break_tracker_popup.sh"
[[ -f "$DAEMON" ]] && { rm -f "$DAEMON"; echo -e "${GREEN}✔  Daemon script removed${NC}"; }

rm -f /tmp/break_tracker_start.txt

echo ""
echo -e "${GREEN}BreakTracker uninstalled.${NC}"
echo "  (Your break log ~/.break_tracker_log.txt was kept.)"
