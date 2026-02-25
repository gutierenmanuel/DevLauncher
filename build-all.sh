#!/usr/bin/env bash
# build-all.sh - Ejecuta el pipeline completo de build
# Compila launchers + installer y deja artefactos en ./dist
# Uso:
#   ./build-all.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER_BUILD="$ROOT_DIR/launcher-go/build.ps1"
INSTALLER_BUILD="$ROOT_DIR/installer-go/build-installer.ps1"
OUTPUTS_DIR="$ROOT_DIR/dist"
VERSION_FILE="$ROOT_DIR/VERSION.txt"

# --- Helpers ---
write_step()  { echo -e "\033[36m==> $1\033[0m"; }
write_ok()    { echo -e "\033[32m✓  $1\033[0m"; }
write_warn()  { echo -e "\033[33m⚠  $1\033[0m"; }

# --- Validaciones ---
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "ERROR: No se encontró VERSION.txt" >&2; exit 1
fi

VERSION_TOKEN=$(head -1 "$VERSION_FILE" | awk '{print $1}')
VERSION_NUMBER="${VERSION_TOKEN#[vV]}"

if [[ -z "$VERSION_NUMBER" ]]; then
    echo "ERROR: No se pudo leer la versión numérica desde VERSION.txt" >&2; exit 1
fi

# Verificar que Go esté instalado
if ! command -v go &>/dev/null; then
    echo "ERROR: Go no está instalado o no está en el PATH" >&2; exit 1
fi

mkdir -p "$OUTPUTS_DIR"

echo ""
echo -e "\033[35m╔════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[35m║  Build All 🏗️                                              ║\033[0m"
echo -e "\033[35m╚════════════════════════════════════════════════════════════╝\033[0m"
echo ""

# --- Compilar launchers ---
write_step "Compilando launchers (Windows/Linux/macOS)..."

cd "$ROOT_DIR/launcher-go"

GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher.exe" .
GOOS=linux   GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher-linux" .
GOOS=darwin  GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher-mac" .

write_ok "Launchers compilados"

# --- Preparar assets para el installer ---
write_step "Preparando assets para embed..."

ASSETS_DIR="$ROOT_DIR/installer-go/assets"

# Limpiar assets anteriores (excepto .gitkeep)
find "$ASSETS_DIR" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} + 2>/dev/null || true

# Copiar launchers compilados
cp "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher.exe"   "$ASSETS_DIR/launcher.exe"
cp "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher-linux"  "$ASSETS_DIR/launcher-linux"
cp "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher-mac"    "$ASSETS_DIR/launcher-mac"

# Copiar VERSION.txt
cp "$VERSION_FILE" "$ASSETS_DIR/VERSION.txt"

# Copiar scripts y static
cp -r "$ROOT_DIR/scripts" "$ASSETS_DIR/scripts"
cp -r "$ROOT_DIR/static"  "$ASSETS_DIR/static"

# Compilar uninstaller
write_step "Compilando uninstaller..."
cd "$ROOT_DIR/installer-go"
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "$ASSETS_DIR/uninstaller.exe" ./cmd/uninstaller
GOOS=linux   GOARCH=amd64 go build -ldflags="-s -w" -o "$ASSETS_DIR/uninstaller-linux" ./cmd/uninstaller
write_ok "Uninstaller compilado"

write_ok "Assets preparados"

# --- Compilar installers ---
write_step "Compilando installer (Windows/Linux)..."

cd "$ROOT_DIR/installer-go"

GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher-inst.exe" .
GOOS=linux   GOARCH=amd64 go build -ldflags="-s -w" -o "$OUTPUTS_DIR/${VERSION_NUMBER}-devlauncher-inst-linux" .

# Limpiar assets después del build (no deben quedar en el repo)
find "$ASSETS_DIR" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} + 2>/dev/null || true

write_ok "Installers compilados"

# --- Resumen ---
echo ""
write_ok "Pipeline completo finalizado"
echo -e "\033[36mCarpeta de salida: $OUTPUTS_DIR\033[0m"
echo -e "\033[36mVersión detectada: $VERSION_NUMBER\033[0m"

ARTIFACTS=(
    "${VERSION_NUMBER}-devlauncher.exe"
    "${VERSION_NUMBER}-devlauncher-linux"
    "${VERSION_NUMBER}-devlauncher-mac"
    "${VERSION_NUMBER}-devlauncher-inst.exe"
    "${VERSION_NUMBER}-devlauncher-inst-linux"
)

echo ""
echo -e "\033[36mArtefactos:\033[0m"
for artifact in "${ARTIFACTS[@]}"; do
    path="$OUTPUTS_DIR/$artifact"
    if [[ -f "$path" ]]; then
        size=$(du -m "$path" | awk '{print $1}')
        printf "  %-40s %6s MB\n" "$artifact" "$size"
    else
        write_warn "$artifact no fue generado"
    fi
done

echo ""