# ☕ BreakTracker

A macOS screensaver + popup system that tracks your away time and greets you with a summary when you return.

---

## How It Works

| When you walk away | The screensaver activates and shows a beautiful dark clock with the exact time your break started — updating live with elapsed time. |
|---|---|
| **When you return** | A popup appears instantly with your break's start time, end time, and total duration. |
| **Optional log** | Click "Log Break" in the popup to append the entry to `~/.break_tracker_log.txt`. |

---

## What's Included

```
BreakTracker/
├── BreakTrackerView.swift         ← Screensaver source (Swift)
├── Info.plist                     ← Bundle manifest
├── break_tracker_popup.sh         ← Background daemon (detects SS + shows popup)
├── com.breaktracker.popup.plist   ← LaunchAgent (auto-starts daemon on login)
├── install.sh                     ← One-command installer
└── uninstall.sh                   ← Clean removal
```

---

## Requirements

- macOS 12 Monterey or later
- Xcode Command Line Tools

**Install Xcode CLT if needed:**
```bash
xcode-select --install
```

---

## Install

```bash
cd BreakTracker
chmod +x install.sh uninstall.sh break_tracker_popup.sh
./install.sh
```

Then go to **System Settings → Screen Saver**, select **BreakTracker**, and set your idle delay.

---

## After Installing

The popup daemon starts immediately in the background and auto-starts on every login.

**Test it quickly:**
1. Lock your screen (`⌃⇧⏏` or menu → Lock Screen)
2. Wait a minute
3. Unlock → the popup appears!

---

## The Screensaver Display

```
┌──────────────────────────────────────────┐
│                                          │
│                                          │
│         ☕  break started at             │
│                                          │
│              2:47:30 PM                  │
│                                          │
│           elapsed  04:32                 │
│        Monday, February 23               │
│                                          │
└──────────────────────────────────────────┘
```

- **Large time** — exact moment the screensaver activated
- **Elapsed** — live counter updating every second
- **Date line** — day of the break

---

## The Popup

```
╔═══════════════════════════════════╗
║           BreakTracker            ║
╠═══════════════════════════════════╣
║  ☕  Break Summary                ║
║                                   ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   ║
║    Started:   2:47:30 PM          ║
║    Ended:     3:12:15 PM          ║
║    Duration:  24 minutes, 45 sec  ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   ║
║                                   ║
║  Welcome back! 👋                 ║
╚═══════════════════════════════════╝
     [Close]          [Log Break]
```

---

## Break Log

If you click **Log Break**, entries are appended to:
```
~/.break_tracker_log.txt
```

Example:
```
Monday, February 23 2026 | Start: 2:47:30 PM | End: 3:12:15 PM | Duration: 24 minutes, 45 seconds
Tuesday, February 24 2026 | Start: 11:03:10 AM | End: 11:18:42 AM | Duration: 15 minutes, 32 seconds
```

---

## Uninstall

```bash
./uninstall.sh
```

Removes the screensaver, daemon, and LaunchAgent. Your log file is kept.

---

## Troubleshooting

**Screensaver doesn't appear in System Settings?**
Drag `build/BreakTracker.saver` directly onto the Screen Saver preference pane, or double-click it in Finder.

**Popup doesn't show?**
Check the daemon is running:
```bash
launchctl list | grep breaktracker
```
Check logs:
```bash
cat ~/.break_tracker_daemon.log
cat ~/.break_tracker.log
```

**"Permission denied" building?**
```bash
chmod +x install.sh break_tracker_popup.sh uninstall.sh
```

**macOS says screensaver is from unidentified developer?**
```bash
xattr -d com.apple.quarantine ~/Library/Screen\ Savers/BreakTracker.saver
```
Or: System Settings → Privacy & Security → Allow Anyway.
