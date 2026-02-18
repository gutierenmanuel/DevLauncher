#!/bin/bash

# Script para inicializar un módulo simple de Go
# Crea una carpeta module/ con estructura básica

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# Nombre del módulo
MODULE_NAME="module"

show_header "Inicializador de Módulo Go 🐹" "Módulo simple y limpio"

info "Módulo: ${BOLD}$MODULE_NAME${NC}"
info "Ubicación: $(pwd)/$MODULE_NAME"
echo ""

# Verificar Go
progress "Verificando dependencias..."
check_command "go" "GO_NOT_FOUND" || exit 1
show_version "go" "version"
echo ""

# Verificar si ya existe
if [ -d "$MODULE_NAME" ]; then
    warning "El directorio '$MODULE_NAME' ya existe"
    echo ""
    
    if ! confirm "¿Deseas eliminarlo y crear uno nuevo?" "n"; then
        info "Instalación cancelada"
        exit 0
    fi
    
    progress "Eliminando directorio existente..."
    rm -rf "$MODULE_NAME"
    success "Directorio eliminado"
    echo ""
fi

# ==========================================
# 1. CREAR ESTRUCTURA BÁSICA
# ==========================================
progress "📁 Creando estructura del módulo..."
mkdir -p "$MODULE_NAME"
cd "$MODULE_NAME"

# Inicializar módulo Go
MODULE_PATH="github.com/user/$MODULE_NAME"
progress "📦 Inicializando go module..."
if ! go mod init "$MODULE_PATH"; then
    handle_error "GO_MOD_INIT_FAILED" "Falló la inicialización del módulo Go" \
        "Verifica que Go esté correctamente instalado"
    exit 1
fi

success "Módulo Go inicializado: $MODULE_PATH"
echo ""

# ==========================================
# 2. CREAR MAIN.GO
# ==========================================
progress "📝 Creando main.go..."

cat > main.go << 'EOF'
package main

import (
"fmt"
)

func main() {
fmt.Println("🚀 ¡Hola desde Go!")
fmt.Println("Módulo inicializado correctamente")
}
EOF

success "main.go creado"
echo ""

# ==========================================
# 3. CREAR .GITIGNORE
# ==========================================
progress "🔒 Creando .gitignore..."

cat > .gitignore << 'EOF'
# Binarios
*.exe
*.exe~
*.dll
*.so
*.dylib
bin/
build/

# Archivos de test
*.test
*.out
coverage.txt
*.prof

# IDEs
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

success ".gitignore creado"
echo ""

# ==========================================
# 4. CREAR README
# ==========================================
progress "📖 Creando README..."

cat > README.md << 'EOF'
# Go Module

Módulo simple de Go inicializado y listo para usar.

## 🚀 Inicio Rápido

### Ejecutar

\`\`\`bash
go run main.go
\`\`\`

### Compilar

\`\`\`bash
go build -o bin/app
./bin/app
\`\`\`

### Con el script build.sh

\`\`\`bash
./build.sh        # Compila para Linux
./build.sh windows # Compila para Windows
\`\`\`

## 📁 Estructura

\`\`\`
module/
├── main.go       # Punto de entrada
├── go.mod        # Dependencias
├── build.sh      # Script de compilación
└── README.md     # Esta documentación
\`\`\`

## 🛠️ Agregar Dependencias

\`\`\`bash
go get github.com/gin-gonic/gin
go mod tidy
\`\`\`

## 📦 Build Multiplataforma

\`\`\`bash
# Linux
GOOS=linux GOARCH=amd64 go build -o bin/app-linux

# Windows
GOOS=windows GOARCH=amd64 go build -o bin/app-windows.exe

# macOS
GOOS=darwin GOARCH=amd64 go build -o bin/app-macos
\`\`\`

## 🧪 Testing

\`\`\`bash
go test ./...
\`\`\`

## 📚 Recursos

- [Go Documentation](https://go.dev/doc/)
- [Go by Example](https://gobyexample.com/)
- [Effective Go](https://go.dev/doc/effective_go)
EOF

success "README.md creado"
echo ""

# ==========================================
# 5. CREAR SCRIPTS DE COMPILACIÓN
# ==========================================
cd ..

# Script build.sh en la raíz
progress "🔨 Creando script build.sh en la raíz..."

cat > build.sh << 'EOF'
#!/bin/bash

# Script de compilación para módulo Go
# Soporta compilación para Linux y Windows

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Go Module Builder 🔨                                     ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "module" ]; then
    echo -e "${RED}✗ No se encuentra el directorio 'module'${NC}"
    echo -e "${YELLOW}  Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
fi

cd module

# Verificar que go esté instalado
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go no está instalado${NC}"
    echo -e "${YELLOW}  Instálalo desde: https://go.dev/dl/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go instalado:${NC} $(go version)"
echo ""

# Crear directorio de salida
mkdir -p bin

# Determinar target (por defecto Linux, o usar argumento)
TARGET="${1:-linux}"

case "$TARGET" in
    linux)
        echo -e "${BLUE}→ Compilando para Linux...${NC}"
        GOOS=linux GOARCH=amd64 go build -o bin/app-linux main.go
        if [ -f "bin/app-linux" ]; then
            chmod +x bin/app-linux
            echo -e "${GREEN}✓ Compilación exitosa: bin/app-linux${NC}"
        else
            echo -e "${RED}✗ Error al compilar${NC}"
            exit 1
        fi
        ;;
    windows)
        echo -e "${BLUE}→ Compilando para Windows...${NC}"
        GOOS=windows GOARCH=amd64 go build -o bin/app-windows.exe main.go
        if [ -f "bin/app-windows.exe" ]; then
            echo -e "${GREEN}✓ Compilación exitosa: bin/app-windows.exe${NC}"
        else
            echo -e "${RED}✗ Error al compilar${NC}"
            exit 1
        fi
        ;;
    all)
        echo -e "${BLUE}→ Compilando para todas las plataformas...${NC}"
        echo ""
        
        # Linux
        echo -e "${YELLOW}Linux...${NC}"
        GOOS=linux GOARCH=amd64 go build -o bin/app-linux main.go
        [ -f "bin/app-linux" ] && echo -e "${GREEN}✓ Linux OK${NC}" || echo -e "${RED}✗ Linux FAIL${NC}"
        
        # Windows
        echo -e "${YELLOW}Windows...${NC}"
        GOOS=windows GOARCH=amd64 go build -o bin/app-windows.exe main.go
        [ -f "bin/app-windows.exe" ] && echo -e "${GREEN}✓ Windows OK${NC}" || echo -e "${RED}✗ Windows FAIL${NC}"
        
        # macOS
        echo -e "${YELLOW}macOS...${NC}"
        GOOS=darwin GOARCH=amd64 go build -o bin/app-macos main.go
        [ -f "bin/app-macos" ] && echo -e "${GREEN}✓ macOS OK${NC}" || echo -e "${RED}✗ macOS FAIL${NC}"
        ;;
    *)
        echo -e "${RED}✗ Target no reconocido: $TARGET${NC}"
        echo -e "${YELLOW}Uso: ./build.sh [linux|windows|all]${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Compilación completada${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Archivos generados:${NC}"
ls -lh bin/
echo ""
EOF

chmod +x build.sh

success "Script build.sh creado en la raíz"
echo ""

# Script dev.sh en la raíz
progress "🚀 Creando script dev.sh en la raíz..."

cat > dev.sh << 'EOF'
#!/bin/bash

# Script de desarrollo para módulo Go
# Ejecuta el módulo directamente

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Go Module Runner 🏃                                      ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "module" ]; then
    echo -e "${RED}✗ No se encuentra el directorio 'module'${NC}"
    echo -e "${YELLOW}  Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
fi

cd module

# Verificar que go esté instalado
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go no está instalado${NC}"
    echo -e "${YELLOW}  Instálalo desde: https://go.dev/dl/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go instalado:${NC} $(go version)"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Ejecutando módulo...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Ejecutar
go run main.go "$@"
EOF

chmod +x dev.sh

success "Script dev.sh creado en la raíz"
echo ""

# ==========================================
# FINALIZACIÓN
# ==========================================

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
success "✅ ¡Módulo Go creado exitosamente!"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "📁 Estructura creada:"
echo -e "  ${GREEN}./module/${NC}        ← Código del módulo"
echo -e "  ${GREEN}./dev.sh${NC}         ← Ejecutar directamente"
echo -e "  ${GREEN}./build.sh${NC}       ← Compilar binario"
echo ""

echo -e "${CYAN}${BOLD}Próximos pasos:${NC}"
echo -e "  ${GREEN}1.${NC} ./dev.sh              ${GRAY}# Ejecutar el módulo${NC}"
echo -e "  ${GREEN}2.${NC} ./build.sh            ${GRAY}# Compilar para Linux${NC}"
echo -e "  ${GREEN}3.${NC} ./build.sh windows    ${GRAY}# Compilar para Windows${NC}"
echo -e "  ${GREEN}4.${NC} ./build.sh all        ${GRAY}# Compilar para todo${NC}"
echo ""

echo -e "${CYAN}${BOLD}Comandos alternativos:${NC}"
echo -e "  ${GREEN}→${NC} cd module && go run main.go     ${GRAY}# Ejecutar manual${NC}"
echo -e "  ${GREEN}→${NC} cd module && go build           ${GRAY}# Compilar manual${NC}"
echo -e "  ${GREEN}→${NC} cd module && go test ./...      ${GRAY}# Ejecutar tests${NC}"
echo ""

success "🎉 ¡Todo listo para desarrollar en Go!"
