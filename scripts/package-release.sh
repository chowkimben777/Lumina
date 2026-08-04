#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?Usage: scripts/package-release.sh <version>}"
ARCH="$(uname -m)"
DIST_DIR="$PROJECT_DIR/dist"
APP_PATH="$PROJECT_DIR/.build/Lumina.app"
ARCHIVE_NAME="Lumina-${VERSION}-macos-${ARCH}.zip"
ARCHIVE_PATH="$DIST_DIR/$ARCHIVE_NAME"

case "$ARCH" in
  arm64 | x86_64) ;;
  *)
    echo "Unsupported release architecture: $ARCH" >&2
    exit 1
    ;;
esac

"$PROJECT_DIR/scripts/build-app.sh"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"
shasum -a 256 "$ARCHIVE_PATH" > "$ARCHIVE_PATH.sha256"

echo "Release archive: $ARCHIVE_PATH"
echo "Checksum: $ARCHIVE_PATH.sha256"
