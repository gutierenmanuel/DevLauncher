#!/usr/bin/env bash
# build-installer.sh - Compila installer para Linux y Windows
# Uso: ./build-installer.sh [--skip-launcher]

set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$INSTALLER_DIR/.." && pwd)"
ASSETS_DIR="$INSTALLER_DIR/assets"
OUTPUTS_DIR="$ROOT/dist"
ICON_PATH="$ROOT/static/devL.ico"
VERSION_FILE="$ROOT/VERSION.txt"
INSTALLER_SYSO="$INSTALLER_DIR/rsrc_windows_amd64.syso"

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
LEGACY_UNINSTALLER_WIN="$VERSION_NUMBER-devlauncher-uninst.exe"
LEGACY_UNINSTALLER_LINUX="$VERSION_NUMBER-devlauncher-uninst-linux"

target_spec() {
    local target="$1"
    case "$target" in
        windows)
            echo "$LAUNCHER_WIN|launcher.exe|uninstaller.exe|windows|amd64|$INSTALLER_WIN"
            ;;
        linux)
            echo "$LAUNCHER_LINUX|launcher-linux|uninstaller-linux|linux|amd64|$INSTALLER_LINUX"
            ;;
        *)
            echo "ERROR: target no soportado: $target" >&2
            return 1
            ;;
    esac
}

echo "Detected version: $VERSION_NUMBER"

mkdir -p "$OUTPUTS_DIR"

# Remove stale uninstaller artifacts from previous builds
rm -f "$OUTPUTS_DIR/$LEGACY_UNINSTALLER_WIN" "$OUTPUTS_DIR/$LEGACY_UNINSTALLER_LINUX"

cleanup() {
    rm -f "$INSTALLER_SYSO"
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

clear_assets() {
    for d in scripts static; do
        [[ -d "$ASSETS_DIR/$d" ]] && rm -rf "$ASSETS_DIR/$d"
    done
    for f in VERSION.txt launcher.exe launcher-linux launcher-mac uninstaller.exe uninstaller-linux uninstaller.sh uninstaller.ps1; do
        [[ -f "$ASSETS_DIR/$f" ]] && rm -f "$ASSETS_DIR/$f"
    done
}

prepare_assets_for_target() {
    local launcher_src="$1"
    local launcher_dest="$2"
    step "Preparando assets para $launcher_dest..."
    clear_assets
    cp -r "$ROOT/scripts" "$ASSETS_DIR/scripts"
    cp -r "$ROOT/static" "$ASSETS_DIR/static"
    cp "$ROOT/VERSION.txt" "$ASSETS_DIR/VERSION.txt"
    if [[ ! -f "$OUTPUTS_DIR/$launcher_src" ]]; then
        echo "ERROR: launcher no encontrado en dist: $launcher_src"
        exit 1
    fi
    cp "$OUTPUTS_DIR/$launcher_src" "$ASSETS_DIR/$launcher_dest"
    echo "  Copiado: $launcher_src -> $launcher_dest"
}

build_uninstaller_asset() {
    local target="$1"
    local uninstaller_asset="$2"
    local goos="$3"
    local goarch="$4"
    step "Compilando asset de uninstaller para $target..."
    GOOS="$goos" GOARCH="$goarch" go build -ldflags="-s -w" -trimpath -o "$ASSETS_DIR/$uninstaller_asset" ./cmd/uninstaller
    echo "  Creado: $uninstaller_asset"
}

# 4. go mod tidy
step "Ejecutando go mod tidy..."
cd "$INSTALLER_DIR"
go mod tidy

# 5. Build Windows installer with Windows-only launcher asset
step "Compilando installer Windows (assets Windows only)..."
IFS='|' read -r WIN_LAUNCHER WIN_LAUNCHER_ASSET WIN_UNINSTALLER_ASSET WIN_GOOS WIN_GOARCH WIN_OUTPUT <<< "$(target_spec windows)"
prepare_assets_for_target "$WIN_LAUNCHER" "$WIN_LAUNCHER_ASSET"
build_uninstaller_asset "windows" "$WIN_UNINSTALLER_ASSET" "$WIN_GOOS" "$WIN_GOARCH"
if [[ -f "$ICON_PATH" ]]; then
    go run github.com/akavel/rsrc@latest -ico "$ICON_PATH" -o "$INSTALLER_SYSO" >/dev/null 2>&1
    echo "  Icono aplicado a installer.exe"
else
    warn "Icono no encontrado: $ICON_PATH"
fi
GOOS="$WIN_GOOS" GOARCH="$WIN_GOARCH" go build -ldflags="-s -w" -trimpath -o "$OUTPUTS_DIR/$WIN_OUTPUT" .

# 6. Build Linux installer with Linux-only launcher asset
step "Compilando installer Linux (assets Linux only)..."
IFS='|' read -r LINUX_LAUNCHER LINUX_LAUNCHER_ASSET LINUX_UNINSTALLER_ASSET LINUX_GOOS LINUX_GOARCH LINUX_OUTPUT <<< "$(target_spec linux)"
prepare_assets_for_target "$LINUX_LAUNCHER" "$LINUX_LAUNCHER_ASSET"
build_uninstaller_asset "linux" "$LINUX_UNINSTALLER_ASSET" "$LINUX_GOOS" "$LINUX_GOARCH"
GOOS="$LINUX_GOOS" GOARCH="$LINUX_GOARCH" go build -ldflags="-s -w" -trimpath -o "$OUTPUTS_DIR/$LINUX_OUTPUT" .

# 7. Clean assets
step "Limpiando assets temporales..."
clear_assets

# 8. Report
echo ""
success "Build completado."
echo "  Outputs: $OUTPUTS_DIR"
for bin in "$INSTALLER_LINUX" "$INSTALLER_WIN"; do
    [[ -f "$OUTPUTS_DIR/$bin" ]] && printf "  %-20s %.1f MB\n" "$bin" "$(du -m "$OUTPUTS_DIR/$bin" | cut -f1)"
done
echo "  Uninstaller ligero generado en instalación (script local)"
