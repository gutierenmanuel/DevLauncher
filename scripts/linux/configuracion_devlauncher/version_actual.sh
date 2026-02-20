#!/bin/bash
# Script: Mostrar versión actual de DevLauncher
# Muestra la versión instalada leyendo VERSION.txt.

set -e

pause_and_exit() {
    local code="${1:-0}"
    read -r -p "Pulsa Enter para continuar"
    exit "$code"
}

INSTALL_DIR="$HOME/.devlauncher"
VERSION_FILE="$INSTALL_DIR/VERSION.txt"

if [ ! -f "$VERSION_FILE" ]; then
    echo "No se encontró VERSION.txt en: $INSTALL_DIR"
    pause_and_exit 1
fi

VERSION_TOKEN="$(awk 'NR==1{print $1}' "$VERSION_FILE")"

if [ -z "$VERSION_TOKEN" ]; then
    echo "No se pudo leer la versión."
    pause_and_exit 1
fi

echo "Versión actual: $VERSION_TOKEN"
pause_and_exit 0
