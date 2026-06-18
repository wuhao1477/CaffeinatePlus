#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CaffeinatePlus"
EXECUTABLE_NAME="CaffeinatePlus"
BUNDLE_ID="com.caffeinateplus.app"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
SCRATCH_DIR="$DIST_DIR/.build"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
DMG_ROOT="$DIST_DIR/dmg-root"

ref_name="${GITHUB_REF_NAME:-}"
if [[ "$ref_name" =~ ^v[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
  app_version="${ref_name#v}"
else
  app_version="0.0.0"
fi

build_number="$(git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
short_sha="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo local)"
dmg_name="CaffeinatePlus-${ref_name:-$short_sha}.dmg"

rm -rf "$DIST_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$DMG_ROOT"

cd "$ROOT_DIR"
swift build -c release --scratch-path "$SCRATCH_DIR"
bin_dir="$(swift build -c release --scratch-path "$SCRATCH_DIR" --show-bin-path)"
cp "$bin_dir/$EXECUTABLE_NAME" "$APP_BUNDLE/Contents/MacOS/$EXECUTABLE_NAME"
if [[ -d "$bin_dir/${EXECUTABLE_NAME}_${EXECUTABLE_NAME}.bundle" ]]; then
  cp -R "$bin_dir/${EXECUTABLE_NAME}_${EXECUTABLE_NAME}.bundle" \
    "$APP_BUNDLE/Contents/Resources/"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$app_version</string>
  <key>CFBundleVersion</key>
  <string>$build_number</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_BUNDLE"

cp -R "$APP_BUNDLE" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$dmg_name"

echo "$DIST_DIR/$dmg_name"
