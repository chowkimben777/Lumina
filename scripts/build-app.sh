#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$BUILD_DIR/Lumina.app"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

export DEVELOPER_DIR
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/ModuleCache"

swift build --package-path "$PROJECT_DIR" --scratch-path "$BUILD_DIR"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/debug/Lumina" "$APP_DIR/Contents/MacOS/Lumina"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

codesign --force --sign - "$APP_DIR"
echo "$APP_DIR"
