#!/bin/bash

# Script para inicializar un proyecto Wails en el repositorio

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Si no se proporciona nombre, usar "wails-app"
PROJECT_NAME="${1:-wails-app}"
TEMPLATE="${2:-react}"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Wails Project Initialization         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configurar PATH para Go y Wails
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar que Wails esté instalado
if ! command -v wails &> /dev/null; then
    echo -e "${RED}❌ Wails no está instalado${NC}"
    echo "   Instálalo con: ./scripts/instaladores/instalar_wails.sh"
    exit 1
fi

echo -e "${GREEN}✓ Wails CLI detectado${NC}"
echo -e "${YELLOW}⟳ Creando proyecto: $PROJECT_NAME${NC}"
echo -e "${YELLOW}⟳ Template: $TEMPLATE${NC}"
echo ""

# Crear proyecto Wails
wails init -n "$PROJECT_NAME" -t "$TEMPLATE"

echo ""
echo -e "${GREEN}✓ Proyecto Wails creado${NC}"
echo ""

# Crear estructura adicional
cd "$PROJECT_NAME"

# Crear script de desarrollo
cat > dev.sh << 'EOF'
#!/bin/bash

# Script para modo desarrollo
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

echo "🚀 Iniciando Wails en modo desarrollo..."
wails dev
EOF

chmod +x dev.sh

# Crear script de compilación
cat > build.sh << 'EOF'
#!/bin/bash

# Script de compilación para Wails (Linux + Windows)

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Wails Build Script - Multi-Platform ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configurar PATH para Go y Wails
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar instalación
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Error: Go no está instalado${NC}"
    exit 1
fi

if ! command -v wails &> /dev/null; then
    echo -e "${RED}✗ Error: Wails no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go $(go version | awk '{print $3}')${NC}"
echo -e "${GREEN}✓ Wails CLI instalado${NC}"
echo ""

# Compilar para Linux
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}Building for Linux (amd64)...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
wails build -platform linux/amd64 -clean

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Linux build completado${NC}"
    ls -lh build/bin/* 2>/dev/null | grep -v '.exe' | awk '{print "  Tamaño: " $5}'
else
    echo -e "${RED}✗ Error en Linux build${NC}"
    exit 1
fi
echo ""

# Compilar para Windows
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}Building for Windows (amd64)...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
wails build -platform windows/amd64

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Windows build completado${NC}"
    ls -lh build/bin/*.exe 2>/dev/null | awk '{print "  Tamaño: " $5}'
else
    echo -e "${RED}✗ Error en Windows build${NC}"
    exit 1
fi
echo ""

# Resumen
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      ✓ Compilación Completada         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "Ejecutables generados en: ${BLUE}build/bin/${NC}"
echo ""
EOF

chmod +x build.sh

# Crear README personalizado
cat > README.md << EOF
# $PROJECT_NAME

Aplicación de escritorio creada con Wails.

## Stack

- 🐹 **Go** - Backend
- ⚛️  **$TEMPLATE** - Frontend
- 🖥️  **Wails** - Framework para aplicaciones de escritorio

## Desarrollo

\`\`\`bash
# Modo desarrollo con hot reload
./dev.sh
# o directamente:
wails dev
\`\`\`

## Build

\`\`\`bash
# Build para Linux y Windows
./build.sh

# Build solo para Linux
wails build -platform linux/amd64

# Build solo para Windows
wails build -platform windows/amd64
\`\`\`

## Estructura del proyecto

\`\`\`
.
├── frontend/        # Código frontend
├── app.go           # Lógica principal de la aplicación
├── main.go          # Punto de entrada
├── wails.json       # Configuración de Wails
├── dev.sh           # Script de desarrollo
├── build.sh         # Script de compilación
└── build/           # Ejecutables compilados
    └── bin/
        ├── $PROJECT_NAME      # Ejecutable Linux
        └── $PROJECT_NAME.exe  # Ejecutable Windows
\`\`\`

## Comandos útiles

\`\`\`bash
wails dev              # Modo desarrollo
wails build            # Build para tu plataforma
wails doctor           # Verificar dependencias
wails generate module  # Generar binding para frontend
\`\`\`

## Recursos

- [Wails Documentation](https://wails.io/)
- [Go Documentation](https://go.dev/doc/)
EOF

cd ..

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Proyecto Wails Inicializado       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "📁 Ubicación: ${BLUE}./$PROJECT_NAME${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo -e "  1. cd $PROJECT_NAME"
echo -e "  2. ./dev.sh"
echo ""
echo -e "${YELLOW}Templates disponibles:${NC}"
echo -e "  vanilla, vue, react, svelte, lit, angular"
echo ""
echo -e "${YELLOW}Para usar otro template:${NC}"
echo -e "  ./scripts/inicializar_repos/init_wails_project.sh mi-app svelte"
echo ""
