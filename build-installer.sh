#!/usr/bin/env bash
# build-installer.sh - Compila installer-linux e installer.exe
# Uso: ./build-installer.sh [--skip-launcher]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_DIR="$ROOT/installer-go"
ASSETS_DIR="$INSTALLER_DIR/assets"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'

step()    { echo -e "${CYAN}==> $*${RESET}"; }
success() { echo -e "${GREEN}✓  $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠  $*${RESET}"; }

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
for bin in launcher.exe launcher-linux launcher-mac; do
    [[ -f "$ROOT/$bin" ]] && cp "$ROOT/$bin" "$ASSETS_DIR/$bin" && echo "  Copiado: $bin"
done

# 4. go mod tidy
step "Ejecutando go mod tidy..."
cd "$INSTALLER_DIR"
go mod tidy

# 5. Build Linux
step "Compilando installer-linux (linux/amd64)..."
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "$ROOT/installer-linux" .

# 6. Build Windows (cross-compile)
step "Compilando installer.exe (windows/amd64)..."
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "$ROOT/installer.exe" . || \
    warn "Cross-compile Windows falló (puede requerir CGO_ENABLED=0 o mingw)"

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
for bin in installer-linux installer.exe; do
    [[ -f "$ROOT/$bin" ]] && printf "  %-20s %.1f MB\n" "$bin" "$(du -m "$ROOT/$bin" | cut -f1)"
done
