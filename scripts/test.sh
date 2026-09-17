#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$PROJECT_DIR/build"
xcrun swiftc -swift-version 5 -parse-as-library \
    "$PROJECT_DIR/Sources/TextCore/TextFileWriter.swift" \
    "$PROJECT_DIR/Tests/TextCoreTests/TextFileWriterTests.swift" \
    -o "$PROJECT_DIR/build/TextCoreTests"
"$PROJECT_DIR/build/TextCoreTests"
