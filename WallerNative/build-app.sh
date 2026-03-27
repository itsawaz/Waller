#!/usr/bin/env bash
# build-app.sh — builds Waller.app from Swift Package sources
set -e

PRODUCT="WallerNative"
APP_NAME="Waller"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR=".build/release"
CONTENTS="${APP_BUNDLE}/Contents"

echo "🔨 Building ${APP_NAME}..."
swift build -c release

echo "📦 Packaging ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${CONTENTS}/MacOS"
mkdir -p "${CONTENTS}/Resources"

# Binary
cp "${BUILD_DIR}/${PRODUCT}" "${CONTENTS}/MacOS/${PRODUCT}"

# Info.plist
cp "Info.plist" "${CONTENTS}/Info.plist"

# Icon (convert PNG → icns if sips is available)
ICON_PNG="AppIcon.png"
if [ -f "${ICON_PNG}" ]; then
    ICONSET="AppIcon.iconset"
    mkdir -p "${ICONSET}"
    for SIZE in 16 32 64 128 256 512 1024; do
        sips -z ${SIZE} ${SIZE} "${ICON_PNG}" --out "${ICONSET}/icon_${SIZE}x${SIZE}.png" > /dev/null 2>&1
    done
    iconutil -c icns "${ICONSET}" -o "${CONTENTS}/Resources/AppIcon.icns"
    rm -rf "${ICONSET}"
    echo "   ✅ Icon converted"
fi

# Make binary executable
chmod +x "${CONTENTS}/MacOS/${PRODUCT}"

echo ""
echo "✅ Done! Waller.app is ready."
echo "   Drag it to /Applications to install."
echo "   Double-click to run — look for the ▶︎ icon in your menu bar."
