#!/bin/zsh
# Build, sign (Developer ID), notarize, staple and package ShotSwitch as a DMG.
#
# One-time setup:
#   1. Xcode > Settings > Accounts > Manage Certificates > + > Developer ID Application
#   2. xcrun notarytool store-credentials ShotSwitch \
#        --key ~/.appstoreconnect/private_keys/AuthKey_XXXX.p8 --key-id XXXX --issuer <issuer-id>
#
# Usage: scripts/release.sh            -> dist/ShotSwitch-<version>.dmg
set -euo pipefail

cd "$(dirname "$0")/.."
SCHEME=ShotSwitch
PROFILE=ShotSwitch          # notarytool keychain profile
BUILD=build
DIST=dist
ARCHIVE=$BUILD/$SCHEME.xcarchive
EXPORT=$BUILD/export
APP=$EXPORT/$SCHEME.app

rm -rf "$BUILD" && mkdir -p "$BUILD" "$DIST"

echo "▸ Archive"
xcodebuild -project $SCHEME.xcodeproj -scheme $SCHEME -configuration Release \
  -archivePath "$ARCHIVE" archive -quiet

echo "▸ Export (Developer ID)"
xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath "$EXPORT" -quiet

VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
DMG=$DIST/$SCHEME-$VERSION.dmg

echo "▸ Notarize app"
ditto -c -k --keepParent "$APP" "$BUILD/$SCHEME.zip"
xcrun notarytool submit "$BUILD/$SCHEME.zip" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"

echo "▸ DMG"
STAGE=$BUILD/dmg
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "$SCHEME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" -quiet

echo "▸ Notarize DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"

echo "▸ Verify"
spctl -a -vv -t install "$DMG"
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E 'Authority|TeamIdentifier'

echo "✓ $DMG"
