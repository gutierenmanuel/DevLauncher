#!/bin/bash
# Script: Desinstalar DevLauncher en Linux
# Ejecuta el uninstaller instalado en el directorio de DevLauncher.

set -e

INSTALL_DIR="$HOME/.devlauncher"
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

UNINSTALL_CMD="bash '$UNINSTALLER'; echo; echo 'Vuelve pronto!'; echo; exec bash"

if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal -- bash -lc "$UNINSTALL_CMD" >/dev/null 2>&1 &
elif command -v x-terminal-emulator >/dev/null 2>&1; then
    x-terminal-emulator -e bash -lc "$UNINSTALL_CMD" >/dev/null 2>&1 &
elif command -v konsole >/dev/null 2>&1; then
    konsole -e bash -lc "$UNINSTALL_CMD" >/dev/null 2>&1 &
elif command -v xterm >/dev/null 2>&1; then
    xterm -e bash -lc "$UNINSTALL_CMD" >/dev/null 2>&1 &
else
    echo "No se encontró emulador de terminal; ejecutando desinstalación aquí."
    bash "$UNINSTALLER"
    echo
    echo "Vuelve pronto!"
    exit 0
fi

echo "Abriendo desinstalación en una nueva terminal..."
sleep 0.2
kill -TERM "$PPID" >/dev/null 2>&1 || true
exit 0
