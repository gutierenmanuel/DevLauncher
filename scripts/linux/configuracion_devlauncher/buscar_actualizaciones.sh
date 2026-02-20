#!/bin/bash
# Script: Buscar actualizaciones de DevLauncher (modo local)
# Muestra versión actual y binarios disponibles sin consultar internet.

set -e

pause_and_exit() {
    local code="${1:-0}"
    read -r -p "Pulsa Enter para continuar"
    exit "$code"
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION.txt"
OUTPUTS_DIR="$ROOT_DIR/outputs"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║      Buscar actualizaciones (modo local / offline)        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ -f "$VERSION_FILE" ]; then
    echo "Versión local: $(head -n 1 "$VERSION_FILE")"
else
    echo "No se encontró VERSION.txt en: $ROOT_DIR"
fi

echo ""
echo "Binarios en outputs/:"
if [ -d "$OUTPUTS_DIR" ]; then
    ls -1 "$OUTPUTS_DIR" | sed 's/^/ - /'
else
    echo " - No existe carpeta outputs"
fi

echo ""
echo "Estado: comprobación online desactivada por ahora."
pause_and_exit 0
