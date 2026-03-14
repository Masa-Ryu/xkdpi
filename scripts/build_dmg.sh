#!/usr/bin/env bash
set -euo pipefail

PRODUCT="xkdpi"
BUILD_DIR=".build/release"
APP_BUNDLE="${PRODUCT}.app"
DMG_NAME="${PRODUCT}.dmg"
BUNDLE_ID="com.xkdpi.displaycontroller"
VERSION="1.0.0"

echo "=== Release ビルド ==="
swift build -c release

echo "=== .app バンドル作成 ==="
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${PRODUCT}" "${APP_BUNDLE}/Contents/MacOS/${PRODUCT}"

cat > "${APP_BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${PRODUCT}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${PRODUCT}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "=== DMG 作成 ==="
rm -f "${DMG_NAME}"
hdiutil create "${DMG_NAME}" \
    -srcfolder "${APP_BUNDLE}" \
    -ov \
    -format UDZO \
    -volname "${PRODUCT}"

echo "=== 完了: ${DMG_NAME} ==="
