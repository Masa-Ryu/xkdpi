#!/usr/bin/env bash
set -euo pipefail

PRODUCT="xkdpi"
APP_BUNDLE="${PRODUCT}.app"
DEST_APP="/Applications/${APP_BUNDLE}"
BUNDLE_ID="com.xkdpi.displaycontroller"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

if ! command -v swift >/dev/null 2>&1; then
    echo "error: swift command not found. Install Xcode or Xcode Command Line Tools first." >&2
    exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
    echo "error: hdiutil command not found. This installer must run on macOS." >&2
    exit 1
fi

echo "=== ${PRODUCT} をビルドします ==="
"${SCRIPT_DIR}/build_dmg.sh"

if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "error: ${APP_BUNDLE} was not generated." >&2
    exit 1
fi

if [[ -e "${DEST_APP}" ]]; then
    read -r -p "${DEST_APP} は既に存在します。上書きしますか？ [y/N] " answer
    case "${answer}" in
        y|Y|yes|YES)
            ;;
        *)
            echo "インストールを中止しました。"
            exit 0
            ;;
    esac
fi

copy_app() {
    rm -rf "${DEST_APP}"
    cp -R "${APP_BUNDLE}" "${DEST_APP}"
}

echo "=== ${DEST_APP} へコピーします ==="
if ! copy_app; then
    echo "通常権限でコピーできませんでした。sudoで再試行します。"
    sudo rm -rf "${DEST_APP}"
    sudo cp -R "${APP_BUNDLE}" "${DEST_APP}"
fi

echo "=== ログイン時自動起動を設定します ==="
"${SCRIPT_DIR}/setup_launch_agent.sh"

echo "=== インストール完了 ==="
echo "アプリ: ${DEST_APP}"
echo "LaunchAgent: ${HOME}/Library/LaunchAgents/${BUNDLE_ID}.plist"
