#!/bin/bash
# Build script for all platforms

set -e

echo "Building launcher for all platforms..."
echo ""

cd "$(dirname "$0")"
ROOT_DIR="$(cd .. && pwd)"
OUTPUT_DIR="$ROOT_DIR/outputs"
ICON_PATH="$ROOT_DIR/static/devL.ico"
SYSO_PATH="$PWD/rsrc_windows_amd64.syso"
VERSION_FILE="$ROOT_DIR/VERSION.txt"

if [[ ! -f "$VERSION_FILE" ]]; then
	echo "ERROR: VERSION.txt not found at $VERSION_FILE"
	exit 1
fi

VERSION_TOKEN="$(awk 'NR==1{print $1}' "$VERSION_FILE")"
VERSION_NUMBER="${VERSION_TOKEN#v}"
VERSION_NUMBER="${VERSION_NUMBER#V}"
if [[ -z "$VERSION_NUMBER" ]]; then
	echo "ERROR: Could not parse numeric version from VERSION.txt"
	exit 1
fi

LAUNCHER_LINUX="$VERSION_NUMBER-devlauncher-linux"
LAUNCHER_WIN="$VERSION_NUMBER-devlauncher.exe"
LAUNCHER_MAC="$VERSION_NUMBER-devlauncher-mac"
mkdir -p "$OUTPUT_DIR"

cleanup() {
	rm -f "$SYSO_PATH"
}
trap cleanup EXIT

# Linux
echo "Building for Linux..."
GOOS=linux GOARCH=amd64 go build -o "$OUTPUT_DIR/$LAUNCHER_LINUX"
echo "✓ $LAUNCHER_LINUX created"

# Windows
echo "Building for Windows..."
if [[ -f "$ICON_PATH" ]]; then
	go run github.com/akavel/rsrc@latest -ico "$ICON_PATH" -o "$SYSO_PATH" >/dev/null 2>&1
	echo "✓ Windows icon resource generated"
else
	echo "⚠ Icon file not found: $ICON_PATH"
fi
GOOS=windows GOARCH=amd64 go build -o "$OUTPUT_DIR/$LAUNCHER_WIN"
echo "✓ $LAUNCHER_WIN created"

# macOS (optional)
echo "Building for macOS..."
GOOS=darwin GOARCH=amd64 go build -o "$OUTPUT_DIR/$LAUNCHER_MAC"
echo "✓ $LAUNCHER_MAC created"

echo ""
echo "Build complete! Binaries created:"
echo "  - $OUTPUT_DIR/$LAUNCHER_LINUX (Linux 64-bit)"
echo "  - $OUTPUT_DIR/$LAUNCHER_WIN   (Windows 64-bit)"
echo "  - $OUTPUT_DIR/$LAUNCHER_MAC   (macOS 64-bit)"
echo ""
echo "File sizes:"
ls -lh "$OUTPUT_DIR/$LAUNCHER_LINUX" "$OUTPUT_DIR/$LAUNCHER_WIN" "$OUTPUT_DIR/$LAUNCHER_MAC" 2>/dev/null | awk '{print "  " $9 ": " $5}'
