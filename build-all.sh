#!/usr/bin/env bash
# build-all.sh - Pipeline completo de build
# Compila launchers + installer y deja artefactos en ./dist
# Uso:
#   ./build-all.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT_DIR/dist"
ASSETS_DIR="$ROOT_DIR/installer-go/assets"
VERSION_FILE="$ROOT_DIR/VERSION.txt"

# --- Helpers ---
step()  { echo -e "\033[36m==> $1\033[0m"; }
ok()    { echo -e "\033[32m✓  $1\033[0m"; }
warn()  { echo -e "\033[33m⚠  $1\033[0m"; }

# --- Validaciones ---
[[ -f "$VERSION_FILE" ]] || { echo "ERROR: No se encontró VERSION.txt" >&2; exit 1; }

VERSION_TOKEN="$(awk 'NR==1{print $1}' "$VERSION_FILE")"
VER="${VERSION_TOKEN#v}"; VER="${VER#V}"
[[ -n "$VER" ]] || { echo "ERROR: No se pudo leer la versión desde VERSION.txt" >&2; exit 1; }

command -v go &>/dev/null || { echo "ERROR: Go no está instalado o no está en el PATH" >&2; exit 1; }

mkdir -p "$DIST"

echo ""
echo -e "\033[35m╔════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[35m║  Build All — DevLauncher v${VER}                 \033[0m"
echo -e "\033[35m╚════════════════════════════════════════════════════════════╝\033[0m"
echo ""

# ── 1. Compilar launchers ─────────────────────────────────────────────────────
step "Compilando launchers via launcher-go/build.sh..."
bash "$ROOT_DIR/launcher-go/build.sh"
ok "Launchers compilados → dist/"

# ── 2. Preparar assets para embed ────────────────────────────────────────────
step "Preparando assets para el installer..."

# Limpiar assets anteriores (excepto .gitkeep)
find "$ASSETS_DIR" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} + 2>/dev/null || true

# Copiar launchers compilados como nombres canónicos
cp "$DIST/${VER}-devlauncher.exe"    "$ASSETS_DIR/launcher.exe"
cp "$DIST/${VER}-devlauncher-linux"  "$ASSETS_DIR/launcher-linux"
cp "$DIST/${VER}-devlauncher-mac"    "$ASSETS_DIR/launcher-mac"

# Copiar VERSION.txt, scripts y static
cp "$VERSION_FILE" "$ASSETS_DIR/VERSION.txt"
cp -r "$ROOT_DIR/scripts" "$ASSETS_DIR/scripts"
cp -r "$ROOT_DIR/static"  "$ASSETS_DIR/static"

ok "Assets copiados"

# ── 3. Compilar uninstaller (va embebido en el installer) ─────────────────────
step "Compilando uninstaller..."
cd "$ROOT_DIR/installer-go"
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -trimpath \
    -o "$ASSETS_DIR/uninstaller.exe" ./cmd/uninstaller
GOOS=linux   GOARCH=amd64 go build -ldflags="-s -w" -trimpath \
    -o "$ASSETS_DIR/uninstaller-linux" ./cmd/uninstaller
ok "Uninstaller compilado → assets/"

# ── 4. Compilar installer ────────────────────────────────────────────────────
step "Compilando installer via installer-go/build.sh..."
bash "$ROOT_DIR/installer-go/build.sh"
ok "Installers compilados → dist/"

# ── 5. Limpiar assets (no deben quedar en el repo) ───────────────────────────
find "$ASSETS_DIR" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} + 2>/dev/null || true

# ── Resumen ───────────────────────────────────────────────────────────────────
echo ""
ok "Pipeline completo — artefactos en dist/:"
ls -lh "$DIST"/ | awk 'NR>1 {printf "  %-45s %s\n", $9, $5}'
echo -e "\033[36mCarpeta de salida: $DIST\033[0m"
echo -e "\033[36mVersión detectada: $VER\033[0m"

ARTIFACTS=(
    "${VER}-devlauncher.exe"
    "${VER}-devlauncher-linux"
    "${VER}-devlauncher-mac"
    "${VER}-devlauncher-inst.exe"
    "${VER}-devlauncher-inst-linux"
)

echo ""
echo -e "\033[36mArtefactos:\033[0m"
for artifact in "${ARTIFACTS[@]}"; do
    path="$DIST/$artifact"
    if [[ -f "$path" ]]; then
        size=$(du -m "$path" | awk '{print $1}')
        printf "  %-40s %6s MB\n" "$artifact" "$size"
    else
        warn "$artifact no fue generado"
    fi
done

echo ""