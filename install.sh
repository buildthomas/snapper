#!/usr/bin/env bash
# Builds Snapper and installs it as ~/Applications/Snapper.app (no admin rights). Re-run to update.
#   SNAPPER_APP_DIR=<dir>          install somewhere else (default ~/Applications)
#   SNAPPER_NO_OPEN=1              don't launch after installing
#   SNAPPER_SIGN_IDENTITY=<name>   codesign identity (default: "Snapper Local Signing" if present, else ad-hoc)
set -euo pipefail
cd "$(dirname "$0")"

APP_DIR="${SNAPPER_APP_DIR:-$HOME/Applications}"
APP="$APP_DIR/Snapper.app"

echo "==> Building (release, $(uname -m))"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/Snapper"

echo "==> Stopping a running Snapper"
pkill -x Snapper 2>/dev/null || true

echo "==> Assembling $APP"
mkdir -p "$APP_DIR"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Snapper"
cp Resources/Info.plist "$APP/Contents/Info.plist"
./scripts/make-icon.sh "$APP/Contents/Resources/Snapper.icns" || echo "warning: icon generation failed (continuing without an icon)"

IDENTITY="${SNAPPER_SIGN_IDENTITY:-}"
if [ -z "$IDENTITY" ] && security find-identity -p codesigning 2>/dev/null | grep -q "Snapper Local Signing"; then
    IDENTITY="Snapper Local Signing"
fi
if [ -n "$IDENTITY" ]; then
    echo "==> Signing with '$IDENTITY'"
    codesign --force --deep --sign "$IDENTITY" "$APP"
else
    echo "==> Ad-hoc signing (macOS may ask for Accessibility permission again after each rebuild; see README)"
    codesign --force --deep --sign - "$APP"
fi
codesign -dv "$APP" 2>&1 | sed 's/^/    /'

if [ -z "${SNAPPER_NO_OPEN:-}" ]; then
    echo "==> Launching"
    open "$APP"
fi
echo "Installed $APP"
echo "Log: ~/Library/Logs/Snapper/snapper.log   Diagnostics: \"$APP/Contents/MacOS/Snapper\" --diagnostics"
