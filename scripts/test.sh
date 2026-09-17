#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$PROJECT_DIR/build"
xcrun swiftc -swift-version 5 -parse-as-library \
    "$PROJECT_DIR/Sources/TextCore/AtomicFileWriter.swift" \
    "$PROJECT_DIR/Sources/TextCore/TextFileWriter.swift" \
    "$PROJECT_DIR/Sources/TextCore/DesktopMenuPolicy.swift" \
    "$PROJECT_DIR/Sources/TextCore/DesktopPastePolicy.swift" \
    "$PROJECT_DIR/Tests/TextCoreTests/TextFileWriterTests.swift" \
    -o "$PROJECT_DIR/build/TextCoreTests"
"$PROJECT_DIR/build/TextCoreTests"
xcrun swiftc -swift-version 5 -parse-as-library -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers \
    "$PROJECT_DIR/Sources/TextCore/AtomicFileWriter.swift" \
    "$PROJECT_DIR/Sources/TextCore/DesktopPastePolicy.swift" \
    "$PROJECT_DIR/Sources/App/ImageFileWriter.swift" \
    "$PROJECT_DIR/Sources/App/ClipboardContent.swift" \
    "$PROJECT_DIR/Tests/ClipboardImageTests.swift" \
    -o "$PROJECT_DIR/build/ClipboardImageTests"
"$PROJECT_DIR/build/ClipboardImageTests"
