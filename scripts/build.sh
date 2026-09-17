#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/build"
APP="$OUTPUT_DIR/剪贴成文.app"
EXTENSION="$APP/Contents/PlugIns/ClipboardFinder.appex"
ARCH="$(uname -m)"
SIGN_IDENTITY="${CLIPTEXT_SIGN_IDENTITY:--}"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$EXTENSION/Contents/MacOS"
bash "$PROJECT_DIR/scripts/build-icon.sh"
cp "$OUTPUT_DIR/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$PROJECT_DIR/Resources/App-Info.plist" "$APP/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/Extension-Info.plist" "$EXTENSION/Contents/Info.plist"
xcrun swiftc -swift-version 5 -O -parse-as-library -target "$ARCH-apple-macosx13.0" \
    -framework AppKit -framework SwiftUI -framework FinderSync -framework ApplicationServices \
    "$PROJECT_DIR/Sources/TextCore/TextFileWriter.swift" "$PROJECT_DIR/Sources/TextCore/DesktopPastePolicy.swift" \
    "$PROJECT_DIR/Sources/App/BrandIcon.swift" "$PROJECT_DIR/Sources/App/DesktopPasteController.swift" "$PROJECT_DIR/Sources/App/ClipboardToTextApp.swift" \
    -o "$APP/Contents/MacOS/ClipboardToText"
xcrun swiftc -swift-version 5 -O -parse-as-library -emit-executable -application-extension \
    -target "$ARCH-apple-macosx13.0" -module-name ClipboardFinder \
    -framework AppKit -framework FinderSync -Xlinker -e -Xlinker _NSExtensionMain \
    "$PROJECT_DIR/Sources/TextCore/DesktopMenuPolicy.swift" \
    "$PROJECT_DIR/Sources/FinderExtension/FinderSync.swift" \
    -o "$EXTENSION/Contents/MacOS/ClipboardFinder"
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" --entitlements "$PROJECT_DIR/Resources/Extension.entitlements" "$EXTENSION"
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" "$APP"
/usr/bin/codesign --verify --deep --strict "$APP"
/usr/bin/plutil -lint "$APP/Contents/Info.plist" "$EXTENSION/Contents/Info.plist"
printf '已构建：%s\n' "$APP"
