#!/usr/bin/env bash
# ============================================================
# BreakTracker – Build & Install Script
# ============================================================
# What this does:
#   1. Compiles BreakTrackerView.swift into a .saver bundle
#   2. Installs the screensaver to ~/Library/Screen Savers/
#   3. Installs the popup daemon script to ~/Library/Scripts/
#   4. Installs a LaunchAgent so the daemon starts on login
#   5. Loads the LaunchAgent immediately
# ============================================================

set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'
YELLOW='\033[1;33m'; NC='\033[0m'

info()    { echo -e "${CYAN}▶  $*${NC}"; }
success() { echo -e "${GREEN}✔  $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠  $*${NC}"; }
error()   { echo -e "${RED}✘  $*${NC}"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ──────────────────────────────────────────────────────────────
# Step 0: Prerequisites
# ──────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║         BreakTracker Installer  v1.0            ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

if ! command -v swiftc &> /dev/null; then
    error "swiftc not found. Please install Xcode Command Line Tools:\n  xcode-select --install"
fi

info "Swift compiler found: $(swiftc --version | head -1)"

# ──────────────────────────────────────────────────────────────
# Step 1: Create .saver bundle structure
# ──────────────────────────────────────────────────────────────
info "Building BreakTracker.saver bundle..."

BUNDLE_DIR="$SCRIPT_DIR/build/BreakTracker.saver"
CONTENTS="$BUNDLE_DIR/Contents"
MACOS="$CONTENTS/MacOS"

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS"
mkdir -p "$CONTENTS/Resources"

# Copy Info.plist
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS/Info.plist"

# Compile Swift → dylib
swiftc \
    -module-name BreakTracker \
    -emit-library \
    -target "$(uname -m)-apple-macosx12.0" \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework ScreenSaver \
    -framework AppKit \
    -framework Foundation \
    -o "$MACOS/BreakTracker" \
    "$SCRIPT_DIR/BreakTrackerView.swift" \
    2>&1

success "Compiled BreakTracker.saver"

# ──────────────────────────────────────────────────────────────
# Step 2: Install screensaver
# ──────────────────────────────────────────────────────────────
SCREENSAVER_DIR="$HOME/Library/Screen Savers"
mkdir -p "$SCREENSAVER_DIR"

DEST_SAVER="$SCREENSAVER_DIR/BreakTracker.saver"
rm -rf "$DEST_SAVER"
cp -R "$BUNDLE_DIR" "$SCREENSAVER_DIR/"

success "Installed screensaver → $DEST_SAVER"

# ──────────────────────────────────────────────────────────────
# Step 3: Install popup daemon script
# ──────────────────────────────────────────────────────────────
SCRIPTS_DIR="$HOME/Library/Scripts/BreakTracker"
mkdir -p "$SCRIPTS_DIR"
DAEMON_DEST="$SCRIPTS_DIR/break_tracker_popup.sh"
cp "$SCRIPT_DIR/break_tracker_popup.sh" "$DAEMON_DEST"
chmod +x "$DAEMON_DEST"

success "Installed popup daemon → $DAEMON_DEST"

# ──────────────────────────────────────────────────────────────
# Step 4: Install LaunchAgent
# ──────────────────────────────────────────────────────────────
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LAUNCHAGENTS_DIR"

PLIST_SRC="$SCRIPT_DIR/com.breaktracker.popup.plist"
PLIST_DEST="$LAUNCHAGENTS_DIR/com.breaktracker.popup.plist"

# Substitute placeholders
sed \
    -e "s|INSTALL_PATH_PLACEHOLDER|$DAEMON_DEST|g" \
    -e "s|HOME_PLACEHOLDER|$HOME|g" \
    "$PLIST_SRC" > "$PLIST_DEST"

success "Installed LaunchAgent → $PLIST_DEST"

# ──────────────────────────────────────────────────────────────
# Step 5: Load LaunchAgent
# ──────────────────────────────────────────────────────────────
info "Loading LaunchAgent..."
launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load "$PLIST_DEST"
success "LaunchAgent loaded and running"

# ──────────────────────────────────────────────────────────────
# Step 6: Instructions
# ──────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  BreakTracker installed successfully! 🎉${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${YELLOW}Next step:${NC} Set BreakTracker as your screensaver"
echo ""
echo "  1. Open  System Settings → Screen Saver"
echo "  2. Select  'BreakTracker'  from the list"
echo "  3. Choose your preferred idle timeout"
echo ""
echo "  The popup daemon is already running in the background."
echo "  When you return from a screensaver, a summary popup"
echo "  will appear showing your break start/end times."
echo ""
echo "  Log of all breaks: ~/.break_tracker_log.txt"
echo ""
