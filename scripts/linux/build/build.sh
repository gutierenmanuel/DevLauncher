#!/bin/bash

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   DevLauncher Build System 🏗️         ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configurar PATH para Go y Wails
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar que Go esté instalado
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Error: Go no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go $(go version | awk '{print $3}')${NC}"
echo -e "${GREEN}✓ Wails CLI instalado${NC}"
echo -e "${GREEN}✓ pnpm $(pnpm --version)${NC}"
echo ""

OUTPUT_DIR="./bin"
mkdir -p "$OUTPUT_DIR"

echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PURPLE}  Construyendo Aplicación Wails${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Limpiar build anterior
echo -e "${YELLOW}🧹 Limpiando...${NC}"
rm -rf wails-app/build wails-app/frontend frontend/dist

# Instalar y compilar frontend
echo -e "${BLUE}📦 Instalando dependencias del frontend...${NC}"
cd frontend && pnpm install

echo -e "${BLUE}🎨 Compilando frontend...${NC}"
pnpm build

if [ ! -f "dist/index.html" ]; then
    echo -e "${RED}✗ Error: Frontend no compilado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Frontend compilado${NC}"
cd ..

# Copiar frontend a wails-app
echo -e "${BLUE}🔗 Copiando frontend a wails-app...${NC}"
mkdir -p wails-app/frontend
cp -r frontend/dist wails-app/frontend/

if [ ! -f "wails-app/frontend/dist/index.html" ]; then
    echo -e "${RED}✗ Error: No se copió correctamente${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Frontend copiado a wails-app/frontend/dist${NC}"

# Compilar Wails
cd wails-app

echo ""
echo -e "${BLUE}🪟 Construyendo para Windows (DEBUG con consola)...${NC}"
wails build -platform windows/amd64 -debug -o devlauncher-debug.exe

if [ -f "build/bin/devlauncher-debug.exe" ]; then
    cp build/bin/devlauncher-debug.exe "../$OUTPUT_DIR/devlauncher-windows-debug.exe"
    echo -e "${GREEN}✅ Debug build completo!${NC}"
else
    echo -e "${RED}✗ Error en build${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🪟 Construyendo para Windows (PRODUCCIÓN sin consola)...${NC}"
wails build -platform windows/amd64 -ldflags "-H windowsgui" -o devlauncher.exe

if [ -f "build/bin/devlauncher.exe" ]; then
    cp build/bin/devlauncher.exe "../$OUTPUT_DIR/devlauncher-windows.exe"
    echo -e "${GREEN}✅ Production build completo!${NC}"
fi

cd ..

echo ""
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Build completado!${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""
echo -e "${YELLOW}🚀 Para copiar a Windows:${NC}"
echo -e "   ${GREEN}bash copy-to-windows.sh${NC}"
echo ""
