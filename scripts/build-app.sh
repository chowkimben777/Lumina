#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$BUILD_DIR/Lumina.app"
BRIDGE_DIR="$BUILD_DIR/MediaBridge"
ADAPTER_DIR="$PROJECT_DIR/ThirdParty/MediaRemoteAdapter"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

export DEVELOPER_DIR
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/ModuleCache"

swift build --package-path "$PROJECT_DIR" --scratch-path "$BUILD_DIR"

rm -rf "$BRIDGE_DIR"
mkdir -p "$BRIDGE_DIR"
xcrun clang -dynamiclib -fobjc-arc -fvisibility=default -arch "$(uname -m)" \
  -framework Foundation -framework AppKit -framework UniformTypeIdentifiers \
  -I"$ADAPTER_DIR/include" -I"$ADAPTER_DIR" \
  "$ADAPTER_DIR/adapter/env.m" \
  "$ADAPTER_DIR/adapter/get.m" \
  "$ADAPTER_DIR/adapter/globals.m" \
  "$ADAPTER_DIR/adapter/keys.m" \
  "$ADAPTER_DIR/adapter/now_playing.m" \
  "$ADAPTER_DIR/adapter/send.m" \
  "$ADAPTER_DIR/private/MediaRemote.m" \
  "$ADAPTER_DIR/utility/helpers.m" \
  -o "$BRIDGE_DIR/MediaRemoteAdapter.dylib"
codesign --force --sign - "$BRIDGE_DIR/MediaRemoteAdapter.dylib"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/debug/Lumina" "$APP_DIR/Contents/MacOS/Lumina"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$BRIDGE_DIR/MediaRemoteAdapter.dylib" "$APP_DIR/Contents/Resources/MediaRemoteAdapter.dylib"
cp "$PROJECT_DIR/Resources/MediaBridge.pl" "$APP_DIR/Contents/Resources/MediaBridge.pl"

codesign --force --sign - "$APP_DIR/Contents/Resources/MediaRemoteAdapter.dylib"
codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
