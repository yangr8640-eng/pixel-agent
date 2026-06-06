#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PixelAgent"
PRODUCT="PixelAgent"
APP_BUNDLE="$ROOT/dist/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

MODE="run"
if [[ "${1:-}" == "--verify" ]]; then
  MODE="verify"
elif [[ "${1:-}" == "--logs" ]]; then
  MODE="logs"
elif [[ "${1:-}" == "--telemetry" ]]; then
  MODE="telemetry"
fi

cd "$ROOT"
/usr/bin/pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build --product "$PRODUCT"
BIN_DIR="$(swift build --show-bin-path)"
BINARY="$BIN_DIR/$PRODUCT"
RESOURCE_BUNDLE="$BIN_DIR/PixelAgent_PixelAgent.bundle"

/bin/rm -rf "$APP_BUNDLE"
/bin/mkdir -p "$MACOS" "$RESOURCES"
/bin/cp "$BINARY" "$MACOS/$APP_NAME"

if [[ -d "$RESOURCE_BUNDLE" ]]; then
  /bin/cp -R "$RESOURCE_BUNDLE" "$APP_BUNDLE/"
fi

/bin/cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>com.pixelagent.desktop</string>
  <key>CFBundleName</key>
  <string>Pixel Agent</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ "$MODE" == "run" || "$MODE" == "verify" || "$MODE" == "logs" || "$MODE" == "telemetry" ]]; then
  /usr/bin/open -n "$APP_BUNDLE"
fi

if [[ "$MODE" == "verify" ]]; then
  sleep 1
  /usr/bin/pgrep -x "$APP_NAME" >/dev/null
  echo "$APP_NAME is running"
elif [[ "$MODE" == "logs" ]]; then
  /usr/bin/log stream --style compact --predicate 'process == "PixelAgent"'
elif [[ "$MODE" == "telemetry" ]]; then
  /usr/bin/log stream --style compact --info --predicate 'process == "PixelAgent"'
fi
