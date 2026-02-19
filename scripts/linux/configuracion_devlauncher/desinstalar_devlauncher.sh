#!/bin/bash
# Script: Desinstalar DevLauncher en Linux
# Ejecuta el uninstaller instalado en el directorio de DevLauncher.

set -e

INSTALL_DIR="$HOME/.devscripts"
UNINSTALLER="$INSTALL_DIR/uninstaller.sh"

if [ ! -f "$UNINSTALLER" ]; then
    echo "No se encontró el uninstaller instalado en: $UNINSTALLER"
    echo "Instala DevLauncher para generar el desinstalador local."
    exit 1
fi

echo "Se ejecutará: $UNINSTALLER"
read -r -p "¿Continuar desinstalación? (s/N): " confirm

if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo "Desinstalación cancelada."
    exit 0
fi

chmod +x "$UNINSTALLER"
bash "$UNINSTALLER"
