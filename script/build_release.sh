#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ClipDeck"
BUNDLE_ID="io.codex.ClipDeck"
MIN_SYSTEM_VERSION="14.0"
RELEASE_VERSION="${CLIPDECK_VERSION:-0.1.3}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_NAME="AppIcon"
APP_ICONSET="$APP_RESOURCES/$APP_ICON_NAME.iconset"
APP_ICNS="$APP_RESOURCES/$APP_ICON_NAME.icns"
ZIP_PATH="$DIST_DIR/${APP_NAME}-v${RELEASE_VERSION}-macos.zip"
DMG_PATH="$DIST_DIR/${APP_NAME}-v${RELEASE_VERSION}-macos.dmg"
SIGNING_IDENTITY="${CLIPDECK_SIGNING_IDENTITY:-}"
STAGING_DIR="$(mktemp -d -t clipdeck-release)"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build -c release
BUILD_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
rm -f "$ZIP_PATH" "$DMG_PATH"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

swift "$ROOT_DIR/script/generate_app_icon.swift" "$APP_ICONSET"
/usr/bin/iconutil -c icns "$APP_ICONSET" -o "$APP_ICNS"
rm -rf "$APP_ICONSET"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>$APP_ICON_NAME</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$RELEASE_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$RELEASE_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -z "$SIGNING_IDENTITY" ]]; then
  SIGNING_IDENTITY="$(/usr/bin/security find-identity -v -p codesigning | sed -n 's/.*\"\(Apple Development: [^\"]*\)\".*/\1/p' | head -n 1)"
fi

if [[ -n "$SIGNING_IDENTITY" ]]; then
  /usr/bin/codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none "$APP_BUNDLE"
else
  /usr/bin/codesign --force --sign - "$APP_BUNDLE"
fi

/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"
/usr/bin/ditto "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
/usr/bin/hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH" >/dev/null

echo "Created: $ZIP_PATH"
echo "Created: $DMG_PATH"
