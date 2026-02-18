#!/bin/bash

# Script de desarrollo para Wails con Hot-Reload
# Autor: DevLauncher Project

set -e  # Salir si hay errores

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Wails Development Mode 🔥           ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configurar PATH para Go y Wails
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar que Go y Wails estén instalados
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Error: Go no está instalado${NC}"
    echo -e "${YELLOW}  Instala Go desde: https://go.dev/dl/${NC}"
    exit 1
fi

if ! command -v wails &> /dev/null; then
    echo -e "${RED}✗ Error: Wails no está instalado${NC}"
    echo -e "${YELLOW}  Instala Wails con: go install github.com/wailsapp/wails/v2/cmd/wails@latest${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go $(go version | awk '{print $3}')${NC}"
echo -e "${GREEN}✓ Wails CLI instalado${NC}"
echo ""

# Verificar pnpm
if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}✗ Error: pnpm no está instalado${NC}"
    echo -e "${YELLOW}  Instala pnpm con: npm install -g pnpm${NC}"
    exit 1
fi

echo -e "${GREEN}✓ pnpm $(pnpm --version)${NC}"
echo ""

# Ya no necesitamos copiar el frontend porque wails.json apunta directamente a ../frontend
echo -e "${GREEN}✓ Usando frontend directamente desde ./frontend/${NC}"
echo -e "${BLUE}  (No es necesario copiar archivos)${NC}"
echo ""

# Verificar dependencias del frontend
echo -e "${YELLOW}⟳ Verificando dependencias del frontend...${NC}"
cd frontend
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}  → Instalando dependencias con pnpm...${NC}"
    pnpm install
else
    echo -e "${GREEN}  ✓ Dependencias ya instaladas${NC}"
fi
cd - > /dev/null
echo ""

# Cambiar al directorio de Wails
cd wails-app

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Iniciando Wails Dev Server...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}🔥 Hot-Reload activado${NC}"
echo -e "${YELLOW}   Frontend: Vite + React + Tailwind${NC}"
echo -e "${YELLOW}   Backend:  Go + WSL Manager${NC}"
echo -e "${YELLOW}   Modo:     Directo (sin copia)${NC}"
echo ""
echo -e "${PURPLE}Presiona Ctrl+C para detener${NC}"
echo ""

# Ejecutar Wails en modo desarrollo
wails dev
