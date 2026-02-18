#!/bin/bash
# Build script for all platforms

set -e

echo "Building launcher for all platforms..."
echo ""

cd "$(dirname "$0")"

# Linux
echo "Building for Linux..."
GOOS=linux GOARCH=amd64 go build -o ../launcher-linux
echo "✓ launcher-linux created"

# Windows
echo "Building for Windows..."
GOOS=windows GOARCH=amd64 go build -o ../launcher.exe
echo "✓ launcher.exe created"

# macOS (optional)
echo "Building for macOS..."
GOOS=darwin GOARCH=amd64 go build -o ../launcher-mac
echo "✓ launcher-mac created"

echo ""
echo "Build complete! Binaries created:"
echo "  - launcher-linux (Linux 64-bit)"
echo "  - launcher.exe   (Windows 64-bit)"
echo "  - launcher-mac   (macOS 64-bit)"
echo ""
echo "File sizes:"
ls -lh ../launcher-linux ../launcher.exe ../launcher-mac 2>/dev/null | awk '{print "  " $9 ": " $5}'
