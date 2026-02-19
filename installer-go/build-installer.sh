#!/usr/bin/env bash
# build-installer.sh - Compila installer/uninstaller para Linux y Windows
# Uso: ./build-installer.sh [--skip-launcher]

set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$INSTALLER_DIR/.." && pwd)"
ASSETS_DIR="$INSTALLER_DIR/assets"
OUTPUTS_DIR="$ROOT/outputs"
ICON_PATH="$ROOT/static/devL.ico"
VERSION_FILE="$ROOT/VERSION.txt"
INSTALLER_SYSO="$INSTALLER_DIR/rsrc_windows_amd64.syso"
UNINSTALLER_SYSO="$INSTALLER_DIR/cmd/uninstaller/rsrc_windows_amd64.syso"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'

step()    { echo -e "${CYAN}==> $*${RESET}"; }
success() { echo -e "${GREEN}✓  $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠  $*${RESET}"; }

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

LAUNCHER_WIN="$VERSION_NUMBER-devlauncher.exe"
LAUNCHER_LINUX="$VERSION_NUMBER-devlauncher-linux"
LAUNCHER_MAC="$VERSION_NUMBER-devlauncher-mac"
INSTALLER_WIN="$VERSION_NUMBER-devlauncher-inst.exe"
INSTALLER_LINUX="$VERSION_NUMBER-devlauncher-inst-linux"
UNINSTALLER_WIN="$VERSION_NUMBER-devlauncher-uninst.exe"
UNINSTALLER_LINUX="$VERSION_NUMBER-devlauncher-uninst-linux"

echo "Detected version: $VERSION_NUMBER"

mkdir -p "$OUTPUTS_DIR"

cleanup() {
    rm -f "$INSTALLER_SYSO" "$UNINSTALLER_SYSO"
}
trap cleanup EXIT

SKIP_LAUNCHER=0
for arg in "$@"; do
    [[ "$arg" == "--skip-launcher" ]] && SKIP_LAUNCHER=1
done

# 1. Optionally rebuild launchers
if [[ $SKIP_LAUNCHER -eq 0 ]]; then
    step "Compilando launchers..."
    if [[ -f "$ROOT/launcher-go/build.sh" ]]; then
        bash "$ROOT/launcher-go/build.sh" --all
    else
        warn "build.sh no encontrado en launcher-go, omitiendo"
    fi
fi

# 2. Clean old assets
step "Preparando assets..."
for d in scripts static; do
    [[ -d "$ASSETS_DIR/$d" ]] && rm -rf "$ASSETS_DIR/$d"
done
for f in VERSION.txt launcher.exe launcher-linux launcher-mac; do
    [[ -f "$ASSETS_DIR/$f" ]] && rm -f "$ASSETS_DIR/$f"
done

# 3. Copy assets
step "Copiando assets..."
cp -r "$ROOT/scripts" "$ASSETS_DIR/scripts"
cp -r "$ROOT/static"  "$ASSETS_DIR/static"
cp "$ROOT/VERSION.txt" "$ASSETS_DIR/VERSION.txt"
for pair in "$LAUNCHER_WIN:launcher.exe" "$LAUNCHER_LINUX:launcher-linux" "$LAUNCHER_MAC:launcher-mac"; do
    src="${pair%%:*}"
    dest="${pair##*:}"
    if [[ -f "$OUTPUTS_DIR/$src" ]]; then
        cp "$OUTPUTS_DIR/$src" "$ASSETS_DIR/$dest"
        echo "  Copiado: $src -> $dest"
    else
        warn "No encontrado en outputs: $src"
    fi
done

# 4. go mod tidy
step "Ejecutando go mod tidy..."
cd "$INSTALLER_DIR"
go mod tidy

# 5. Build Linux installer + uninstaller
step "Compilando installer-linux y uninstaller-linux (linux/amd64)..."
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/$INSTALLER_LINUX" .
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/$UNINSTALLER_LINUX" ./cmd/uninstaller

# 6. Build Windows installer + uninstaller (cross-compile)
step "Compilando installer.exe y uninstaller.exe (windows/amd64)..."
if [[ -f "$ICON_PATH" ]]; then
    go run github.com/akavel/rsrc@latest -ico "$ICON_PATH" -o "$INSTALLER_SYSO" >/dev/null 2>&1
    go run github.com/akavel/rsrc@latest -ico "$ICON_PATH" -o "$UNINSTALLER_SYSO" >/dev/null 2>&1
    echo "  Icono aplicado a installer.exe y uninstaller.exe"
else
    warn "Icono no encontrado: $ICON_PATH"
fi
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/$INSTALLER_WIN" .
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/$UNINSTALLER_WIN" ./cmd/uninstaller

# 7. Clean assets
step "Limpiando assets temporales..."
for d in scripts static; do
    [[ -d "$ASSETS_DIR/$d" ]] && rm -rf "$ASSETS_DIR/$d"
done
for f in VERSION.txt launcher.exe launcher-linux launcher-mac; do
    [[ -f "$ASSETS_DIR/$f" ]] && rm -f "$ASSETS_DIR/$f"
done

# 8. Report
echo ""
success "Build completado."
echo "  Outputs: $OUTPUTS_DIR"
for bin in "$INSTALLER_LINUX" "$INSTALLER_WIN" "$UNINSTALLER_LINUX" "$UNINSTALLER_WIN"; do
    [[ -f "$OUTPUTS_DIR/$bin" ]] && printf "  %-20s %.1f MB\n" "$bin" "$(du -m "$OUTPUTS_DIR/$bin" | cut -f1)"
done
