#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="com.xkdpi.displaycontroller"
PLIST_NAME="${BUNDLE_ID}.plist"
AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_PATH="${AGENTS_DIR}/${PLIST_NAME}"
APP_PATH="/Applications/xkdpi.app/Contents/MacOS/xkdpi"

mkdir -p "${AGENTS_DIR}"

cat > "${PLIST_PATH}" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${BUNDLE_ID}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/xkdpi.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/xkdpi.err</string>
</dict>
</plist>
PLIST

launchctl load "${PLIST_PATH}"
echo "LaunchAgent 登録完了: ${PLIST_PATH}"
