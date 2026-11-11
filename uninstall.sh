#!/usr/bin/env bash
# Removes Snapper completely: the app, Launch at Login, settings, logs and its Accessibility permission entry.
set -uo pipefail
APP="${SNAPPER_APP_DIR:-$HOME/Applications}/Snapper.app"

if [ -x "$APP/Contents/MacOS/Snapper" ]; then
    pkill -x Snapper 2>/dev/null || true
    "$APP/Contents/MacOS/Snapper" --unregister-login || true
fi
pkill -x Snapper 2>/dev/null || true
rm -rf "$APP"
defaults delete com.thoeksema.Snapper 2>/dev/null || true
rm -rf "$HOME/Library/Logs/Snapper"
tccutil reset Accessibility com.thoeksema.Snapper 2>/dev/null || true
echo "Snapper removed."
