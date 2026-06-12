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

if pgrep -x "${PRODUCT}" >/dev/null 2>&1; then
    echo "error: ${PRODUCT} is running. Quit it from the status bar menu, then run this installer again." >&2
    exit 1
fi

echo "=== Building ${PRODUCT} ==="
"${SCRIPT_DIR}/build_dmg.sh"

if [[ ! -d "${APP_BUNDLE}" ]]; then
    echo "error: ${APP_BUNDLE} was not generated." >&2
    exit 1
fi

if [[ -e "${DEST_APP}" ]]; then
    read -r -p "${DEST_APP} already exists. Overwrite it? [y/N] " answer
    case "${answer}" in
        y|Y|yes|YES)
            ;;
        *)
            echo "Installation canceled."
            exit 0
            ;;
    esac
fi

copy_app() {
    rm -rf "${DEST_APP}"
    cp -R "${APP_BUNDLE}" "${DEST_APP}"
}

echo "=== Copying to ${DEST_APP} ==="
if ! copy_app; then
    echo "Could not copy with normal permissions. Retrying with sudo."
    sudo rm -rf "${DEST_APP}"
    sudo cp -R "${APP_BUNDLE}" "${DEST_APP}"
fi

echo "=== Installation complete ==="
echo "App: ${DEST_APP}"
echo "Configure launch at login from the app's status bar menu."
