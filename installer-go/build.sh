#!/usr/bin/env bash
# build.sh – Compila el installer (y uninstaller) a dist/
# Uso:
#   ./build.sh              → compila Linux + Windows + macOS
#   ./build.sh --linux      → solo Linux
#   ./build.sh --windows    → solo Windows
#   ./build.sh --mac        → solo macOS

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
ROOT="$(cd .. && pwd)"
DIST="$ROOT/dist"
ICON="$ROOT/static/devL.ico"
VERSION_FILE="$ROOT/VERSION.txt"
SYSO="$PWD/rsrc_windows_amd64.syso"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
step()    { echo -e "${CYAN}==> $*${RESET}"; }
ok()      { echo -e "${GREEN}✓  $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠  $*${RESET}"; }

# ── Versión ──────────────────────────────────────────────────────────────────
[[ -f "$VERSION_FILE" ]] || { echo "ERROR: VERSION.txt no encontrado"; exit 1; }
VER_TOKEN="$(awk 'NR==1{print $1}' "$VERSION_FILE")"
VER="${VER_TOKEN#v}"; VER="${VER#V}"
[[ -n "$VER" ]] || { echo "ERROR: versión vacía en VERSION.txt"; exit 1; }
echo "Versión: $VER"

# ── Destinos ─────────────────────────────────────────────────────────────────
INST_LINUX="$VER-devlauncher-inst-linux"
INST_WIN="$VER-devlauncher-inst.exe"
INST_MAC="$VER-devlauncher-inst-mac"

mkdir -p "$DIST"

# ── Limpieza SYSO al salir ───────────────────────────────────────────────────
cleanup() { rm -f "$SYSO"; }
trap cleanup EXIT

# ── Parseo de flags ──────────────────────────────────────────────────────────
BUILD_LINUX=1; BUILD_WIN=1; BUILD_MAC=1
for arg in "$@"; do
    case "$arg" in
        --linux)   BUILD_WIN=0; BUILD_MAC=0 ;;
        --windows) BUILD_LINUX=0; BUILD_MAC=0 ;;
        --mac)     BUILD_LINUX=0; BUILD_WIN=0 ;;
    esac
done

LDFLAGS="-s -w"

# ── Builds ───────────────────────────────────────────────────────────────────
if [[ $BUILD_LINUX -eq 1 ]]; then
    step "Compilando installer Linux → dist/$INST_LINUX"
    GOOS=linux GOARCH=amd64 go build -ldflags="$LDFLAGS" -trimpath -o "$DIST/$INST_LINUX" .
    ok "$INST_LINUX  ($(du -sh "$DIST/$INST_LINUX" | cut -f1))"
fi

if [[ $BUILD_WIN -eq 1 ]]; then
    step "Compilando installer Windows → dist/$INST_WIN"
    if [[ -f "$ICON" ]]; then
        go run github.com/akavel/rsrc@latest -ico "$ICON" -o "$SYSO" >/dev/null 2>&1
        ok "Icono Windows aplicado"
    else
        warn "Icono no encontrado: $ICON"
    fi
    GOOS=windows GOARCH=amd64 go build -ldflags="$LDFLAGS" -trimpath -o "$DIST/$INST_WIN" .
    ok "$INST_WIN  ($(du -sh "$DIST/$INST_WIN" | cut -f1))"
fi

if [[ $BUILD_MAC -eq 1 ]]; then
    step "Compilando installer macOS → dist/$INST_MAC"
    GOOS=darwin GOARCH=amd64 go build -ldflags="$LDFLAGS" -trimpath -o "$DIST/$INST_MAC" .
    ok "$INST_MAC  ($(du -sh "$DIST/$INST_MAC" | cut -f1))"
fi

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
ok "Build completado → $DIST"
