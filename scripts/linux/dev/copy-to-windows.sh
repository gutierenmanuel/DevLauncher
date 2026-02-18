#!/bin/bash

# Script para copiar el ejecutable a Windows y ejecutarlo

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Copiar a Windows y Ejecutar         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar que exista el ejecutable
if [ ! -f "bin/devlauncher-windows-debug.exe" ]; then
    echo -e "${RED}✗ Error: No se encontró bin/devlauncher-windows-debug.exe${NC}"
    echo -e "${YELLOW}  Ejecuta primero: bash build.sh${NC}"
    exit 1
fi

# Detectar el usuario de Windows
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')

if [ -z "$WIN_USER" ]; then
    echo -e "${RED}✗ Error: No se pudo detectar el usuario de Windows${NC}"
    echo -e "${YELLOW}  ¿Estás ejecutando esto desde WSL?${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Usuario de Windows detectado: $WIN_USER${NC}"

# Crear carpeta en Windows
WIN_PATH="/mnt/c/Users/$WIN_USER/Desktop/DevLauncher"
echo -e "${YELLOW}⟳ Creando carpeta en: $WIN_PATH${NC}"
mkdir -p "$WIN_PATH"

# Copiar archivos
echo -e "${YELLOW}⟳ Copiando ejecutables...${NC}"
cp bin/devlauncher-windows-debug.exe "$WIN_PATH/"
cp bin/devlauncher-windows.exe "$WIN_PATH/" 2>/dev/null || true
cp bin/run-debug.bat "$WIN_PATH/" 2>/dev/null || true

echo -e "${GREEN}✓ Archivos copiados a: C:\\Users\\$WIN_USER\\Desktop\\DevLauncher${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Listo para ejecutar en Windows!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📁 Ubicación:${NC}"
echo -e "   C:\\Users\\$WIN_USER\\Desktop\\DevLauncher"
echo ""
echo -e "${YELLOW}🚀 Para ejecutar:${NC}"
echo -e "   1. Abre el Explorador de Windows"
echo -e "   2. Ve a: Escritorio > DevLauncher"
echo -e "   3. Doble click en: ${GREEN}run-debug.bat${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo -e "   NO ejecutes el .exe desde WSL (\\\\wsl.localhost)"
echo -e "   Debe ejecutarse desde Windows directamente"
echo ""
echo -e "${YELLOW}📝 Requisitos (descargar si no tienes):${NC}"
echo -e "   1. WebView2 Runtime:"
echo -e "      https://go.microsoft.com/fwlink/p/?LinkId=2124703"
echo -e "   2. Visual C++ Redistributables:"
echo -e "      https://aka.ms/vs/17/release/vc_redist.x64.exe"
echo ""

# Opcional: abrir la carpeta en el explorador de Windows
if command -v explorer.exe &> /dev/null; then
    echo -e "${BLUE}🔍 Abriendo carpeta en Windows...${NC}"
    explorer.exe "C:\\Users\\$WIN_USER\\Desktop\\DevLauncher"
fi
