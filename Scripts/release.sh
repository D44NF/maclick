#!/bin/zsh
# Builds MaClick (Release) and packages it into dist/MaClick-<version>.dmg.
#
# Not signed with a paid Apple Developer ID and not notarized, so first-time
# openers need to right-click > Open once (see the README's Install section).
# Run locally after `xcodegen generate` has a working Config/Local.xcconfig.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="MaClick"

echo "▸ Regenerating the Xcode project…"
xcodegen generate

VERSION="$(sed -nE 's/.*MARKETING_VERSION: *"([^"]+)".*/\1/p' project.yml | head -1)"
[[ -n "$VERSION" ]] || { echo "✗ Could not read MARKETING_VERSION from project.yml" >&2; exit 1; }
echo "▸ Building MaClick $VERSION (Release)…"

rm -rf dist
mkdir -p dist

xcodebuild build \
    -project MaClick.xcodeproj \
    -target "$APP_NAME" \
    -configuration Release

BUILT_PRODUCTS_DIR="$(xcodebuild -project MaClick.xcodeproj -target "$APP_NAME" -configuration Release -showBuildSettings 2>/dev/null | awk -F'= ' '/ BUILT_PRODUCTS_DIR/{print $2; exit}')"
APP="$BUILT_PRODUCTS_DIR/$APP_NAME.app"
[[ -d "$APP" ]] || { echo "✗ $APP not found after build" >&2; exit 1; }

echo "▸ Building the DMG…"
DMG="dist/$APP_NAME-$VERSION.dmg"
set +e
create-dmg \
    --volname "$APP_NAME" \
    --window-size 600 400 \
    --icon-size 120 \
    --icon "$APP_NAME.app" 150 185 \
    --app-drop-link 450 185 \
    "$DMG" \
    "$APP"
dmg_status=$?
set -e
# create-dmg can exit non-zero on a harmless Finder/AppleScript styling
# race even when it produced a valid DMG — only the file matters.
[[ -s "$DMG" ]] || { echo "✗ create-dmg failed (exit $dmg_status), no DMG produced" >&2; exit 1; }

echo "✓ Ready: $DMG"
echo "  Next: git tag -a v$VERSION -m \"v$VERSION\" && git push origin v$VERSION"
echo "        gh release create v$VERSION \"$DMG\" --title \"v$VERSION\" --notes \"...\""
