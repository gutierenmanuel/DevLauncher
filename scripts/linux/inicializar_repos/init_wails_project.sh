#!/bin/bash

# Script para inicializar un proyecto Wails completo
# Estructura: frontend/ + backend/ + wails-app/

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "Inicializador de Proyecto Wails 🚀" "Frontend + Backend + Wails App"

info "Estructura que se creará:"
echo -e "  ${GREEN}./frontend/${NC}      ← React + Vite + shadcn/ui"
echo -e "  ${GREEN}./backend/${NC}       ← Módulo Go"
echo -e "  ${GREEN}./wails-app/${NC}     ← Proyecto Wails"
echo -e "  ${GREEN}./dev.sh${NC}         ← Desarrollo (referencias directas)"
echo -e "  ${GREEN}./build.sh${NC}       ← Compilación (sin copias)"
echo ""

if ! confirm "¿Deseas continuar?" "y"; then
    info "Instalación cancelada"
    exit 0
fi
echo ""

# Verificar dependencias
progress "Verificando dependencias..."
check_command "go" "GO_NOT_FOUND" || exit 1
check_command "wails" "WAILS_NOT_FOUND" || exit 1
check_command "pnpm" "PNPM_NOT_FOUND" || exit 1
echo ""

# ==========================================
# 1. CREAR FRONTEND
# ==========================================
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  1/4 - Inicializando Frontend${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Ejecutar init_frontend_project.sh
if ! bash "$SCRIPT_DIR/init_frontend_project.sh"; then
    handle_error "FRONTEND_INIT_FAILED" "Falló la inicialización del frontend" \
        "Verifica los errores anteriores"
    exit 1
fi

# Eliminar el dev.sh que genera init_frontend_project.sh (lo crearemos personalizado después)
rm -f dev.sh

success "Frontend inicializado"
echo ""

# ==========================================
# 2. CREAR BACKEND
# ==========================================
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  2/4 - Inicializando Backend Go${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

progress "📁 Creando estructura backend..."
mkdir -p backend
cd backend

# Inicializar módulo Go
MODULE_PATH="github.com/user/backend"
progress "📦 Inicializando go module..."
if ! go mod init "$MODULE_PATH"; then
    handle_error "GO_MOD_INIT_FAILED" "Falló la inicialización del módulo Go" \
        "Verifica que Go esté correctamente instalado"
    exit 1
fi

# Crear estructura básica para Wails
cat > app.go << 'EOF'
package backend

import (
"context"
"fmt"
)

// App struct
type App struct {
ctx context.Context
}

// NewApp creates a new App application struct
func NewApp() *App {
return &App{}
}

// startup is called when the app starts. The context is saved
// so we can call the runtime methods
func (a *App) Startup(ctx context.Context) {
a.ctx = ctx
}

// Greet returns a greeting for the given name
func (a *App) Greet(name string) string {
return fmt.Sprintf("¡Hola %s! 🚀", name)
}

// GetMessage returns a sample message
func (a *App) GetMessage() string {
return "¡Backend de Wails funcionando correctamente!"
}
EOF

cat > .gitignore << 'EOF'
# Binarios
*.exe
*.exe~
*.dll
*.so
*.dylib

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

cd ..
success "Backend inicializado"
echo ""

# ==========================================
# 3. CREAR WAILS-APP
# ==========================================
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  3/4 - Inicializando Wails App${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

progress "📦 Creando proyecto Wails..."
mkdir -p wails-app
cd wails-app

# Inicializar módulo Go para wails-app
if ! go mod init github.com/user/wails-app; then
    handle_error "GO_MOD_INIT_FAILED" "Falló la inicialización del módulo Wails" \
        "Verifica que Go esté correctamente instalado"
    exit 1
fi

# Crear main.go
cat > main.go << 'EOF'
package main

import (
"embed"
"log"

"github.com/wailsapp/wails/v2"
"github.com/wailsapp/wails/v2/pkg/options"
"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
// Create an instance of the app structure
app := NewApp()

// Create application with options
err := wails.Run(&options.App{
Title:  "Wails App",
Width:  1024,
Height: 768,
AssetServer: &assetserver.Options{
Assets: assets,
},
BackgroundColour: &options.RGBA{R: 27, G: 38, B: 54, A: 1},
OnStartup:        app.startup,
Bind: []interface{}{
app,
},
})

if err != nil {
log.Fatal("Error:", err)
}
}
EOF

# Crear app.go que usa el backend
cat > app.go << 'EOF'
package main

import (
"context"
)

// App struct
type App struct {
ctx context.Context
}

// NewApp creates a new App application struct
func NewApp() *App {
return &App{}
}

// startup is called when the app starts
func (a *App) startup(ctx context.Context) {
a.ctx = ctx
}

// Greet returns a greeting for the given name
func (a *App) Greet(name string) string {
return "¡Hola " + name + " desde Wails! 🚀"
}
EOF

# Crear wails.json configurado para usar carpetas externas
cat > wails.json << 'EOF'
{
  "$schema": "https://wails.io/schemas/config.v2.json",
  "name": "wails-app",
  "outputfilename": "wails-app",
  "frontend:install": "pnpm install",
  "frontend:build": "pnpm build",
  "frontend:dev:watcher": "pnpm dev",
  "frontend:dev:serverUrl": "auto",
  "author": {
    "name": "user",
    "email": "user@example.com"
  }
}
EOF

cat > .gitignore << 'EOF'
# Wails
build/
frontend/

# Go
*.exe
*.exe~
*.dll
*.so
*.dylib

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

cd ..
success "Wails App inicializado"
echo ""

# ==========================================
# 4. CREAR SCRIPTS DE DESARROLLO Y BUILD
# ==========================================
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}  4/4 - Creando Scripts de Desarrollo y Build${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Script dev.sh
progress "🚀 Creando dev.sh..."
cat > dev.sh << 'EOF'
#!/bin/bash

# Script de desarrollo para Wails con Hot-Reload
# Usa carpetas frontend y backend directamente (sin copiar)

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Wails Development Mode 🔥                                ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configurar PATH para Go y Wails
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar dependencias
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go no está instalado${NC}"
    exit 1
fi

if ! command -v wails &> /dev/null; then
    echo -e "${RED}✗ Wails no está instalado${NC}"
    exit 1
fi

if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}✗ pnpm no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go instalado:${NC} $(go version | awk '{print $3}')"
echo -e "${GREEN}✓ Wails instalado${NC}"
echo -e "${GREEN}✓ pnpm instalado${NC}"
echo ""

# Crear symlink del frontend en wails-app si no existe
if [ ! -L "wails-app/frontend" ]; then
    echo -e "${YELLOW}→ Creando enlace simbólico del frontend...${NC}"
    ln -sf ../frontend wails-app/frontend
    echo -e "${GREEN}✓ Enlace creado${NC}"
fi
echo ""

# Verificar dependencias del frontend
echo -e "${YELLOW}⟳ Verificando dependencias del frontend...${NC}"
cd frontend
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}  → Instalando dependencias...${NC}"
    pnpm install
else
    echo -e "${GREEN}  ✓ Dependencias ya instaladas${NC}"
fi
cd ..
echo ""

# Cambiar a wails-app y ejecutar
cd wails-app

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Iniciando Wails Dev Server...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}🔥 Hot-Reload activado${NC}"
echo -e "${YELLOW}   Frontend: ../frontend (enlace simbólico)${NC}"
echo -e "${YELLOW}   Backend:  ../backend${NC}"
echo -e "${YELLOW}   Modo:     Referencia directa (sin copias)${NC}"
echo ""
echo -e "${PURPLE}Presiona Ctrl+C para detener${NC}"
echo ""

# Ejecutar Wails en modo desarrollo
wails dev
EOF

chmod +x dev.sh
success "dev.sh creado"
echo ""

# Script build.sh
progress "🔨 Creando build.sh..."
cat > build.sh << 'EOF'
#!/bin/bash

# Script de compilación para Wails (solo Linux)
# Usa carpetas frontend y backend directamente (sin copiar)

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Wails Build Script 🔨                                    ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configurar PATH
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Verificar dependencias
if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go no está instalado${NC}"
    exit 1
fi

if ! command -v wails &> /dev/null; then
    echo -e "${RED}✗ Wails no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go instalado:${NC} $(go version | awk '{print $3}')"
echo -e "${GREEN}✓ Wails instalado${NC}"
echo ""

# Crear symlink del frontend en wails-app si no existe
if [ ! -L "wails-app/frontend" ]; then
    echo -e "${YELLOW}→ Creando enlace simbólico del frontend...${NC}"
    ln -sf ../frontend wails-app/frontend
    echo -e "${GREEN}✓ Enlace creado${NC}"
fi
echo ""

# Compilar frontend primero
echo -e "${YELLOW}⟳ Compilando frontend...${NC}"
cd frontend
if ! pnpm build; then
    echo -e "${RED}✗ Error al compilar frontend${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Frontend compilado${NC}"
cd ..
echo ""

# Cambiar a wails-app
cd wails-app

# Compilar para Linux
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Compilando para Linux (amd64)...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

if ! wails build -platform linux/amd64 -clean; then
    echo -e "${RED}✗ Error en compilación${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Compilación Completada${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

if [ -f "build/bin/wails-app" ]; then
    echo -e "${BLUE}Ejecutable generado:${NC}"
    ls -lh build/bin/wails-app | awk '{print "  wails-app → " $5}'
    echo ""
    echo -e "${GREEN}Ubicación:${NC} ./wails-app/build/bin/wails-app"
else
    echo -e "${RED}✗ No se encontró el ejecutable${NC}"
    exit 1
fi
echo ""
EOF

chmod +x build.sh
success "build.sh creado"
echo ""

# Crear README
progress "📝 Creando README..."
cat > README.md << 'EOF'
# Wails Project

Aplicación de escritorio moderna con Wails v2.

## 🚀 Stack Tecnológico

- **Frontend**: React + Vite + TypeScript + Tailwind CSS + shadcn/ui
- **Backend**: Go
- **Desktop**: Wails v2
- **Package Manager**: pnpm

## 📁 Estructura del Proyecto

```
.
├── frontend/          # Aplicación React (referenciada por wails-app)
├── backend/           # Lógica de negocio en Go (opcional)
├── wails-app/         # Proyecto Wails principal
│   ├── main.go        # Punto de entrada
│   ├── app.go         # Lógica de la aplicación
│   ├── wails.json     # Configuración Wails
│   └── frontend/      # Symlink a ../frontend
├── dev.sh             # Script de desarrollo
├── build.sh           # Script de compilación
└── README.md          # Este archivo
```

## 🛠️ Desarrollo

### Iniciar servidor de desarrollo

```bash
./dev.sh
```

Esto iniciará:
- Frontend en modo desarrollo (Vite HMR)
- Backend Go con hot-reload
- Ventana de Wails con DevTools

### Desarrollo manual

```bash
cd wails-app
wails dev
```

## 🏗️ Compilación

### Build para Linux

```bash
./build.sh
```

El ejecutable se generará en: `wails-app/build/bin/wails-app`

### Build manual

```bash
cd wails-app
wails build
```

### Build multiplataforma

```bash
cd wails-app

# Linux
wails build -platform linux/amd64

# Windows (desde Linux)
wails build -platform windows/amd64

# macOS (desde macOS)
wails build -platform darwin/universal
```

## 📝 Notas Importantes

### Enlaces Simbólicos

El proyecto usa enlaces simbólicos para evitar copiar archivos:
- `wails-app/frontend/` → enlace a `../frontend/`

Esto permite:
✅ Desarrollo más rápido (sin copias)
✅ Sincronización automática
✅ Menos uso de disco

### Modificar el Frontend

Los cambios en `frontend/` se reflejan automáticamente en desarrollo.

Para agregar componentes shadcn/ui:

```bash
cd frontend
pnpx shadcn@latest add button card dialog
```

### Modificar el Backend

Edita los archivos en:
- `backend/app.go` - Lógica de negocio
- `wails-app/app.go` - Bindings para el frontend

### Exponer Funciones al Frontend

En `wails-app/app.go`:

```go
func (a *App) MyFunction() string {
    return "Hola desde Go!"
}
```

En el frontend:

```typescript
import { MyFunction } from '../wailsjs/go/main/App'

const result = await MyFunction()
```

## 🧪 Testing

```bash
# Backend tests
cd backend
go test ./...

# Frontend tests
cd frontend
pnpm test
```

## 📚 Recursos

- [Wails Documentation](https://wails.io/)
- [Wails Examples](https://github.com/wailsapp/wails/tree/master/v2/examples)
- [Go Documentation](https://go.dev/doc/)
- [React Documentation](https://react.dev/)
- [shadcn/ui](https://ui.shadcn.com/)

## 🔧 Comandos Útiles

```bash
# Verificar instalación de Wails
wails doctor

# Generar bindings TypeScript
cd wails-app && wails generate module

# Ver logs en desarrollo
# Los logs de Go aparecen en la terminal
# Los logs del frontend aparecen en DevTools (F12)
```

## 🐛 Troubleshooting

### El frontend no se actualiza en desarrollo

```bash
cd frontend
pnpm install
pnpm dev  # Verifica que Vite funcione solo
```

### Error al compilar

```bash
cd wails-app
wails doctor  # Verifica dependencias
go mod tidy   # Limpia dependencias Go
```

### Symlink no funciona

```bash
rm -f wails-app/frontend
ln -sf ../frontend wails-app/frontend
```
EOF

success "README.md creado"
echo ""

# ==========================================
# FINALIZACIÓN
# ==========================================

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
success "✅ ¡Proyecto Wails completo creado exitosamente!"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "📁 Estructura creada:"
echo -e "  ${GREEN}./frontend/${NC}        ← React + Vite + shadcn/ui + Storybook"
echo -e "  ${GREEN}./backend/${NC}         ← Módulo Go para lógica de negocio"
echo -e "  ${GREEN}./wails-app/${NC}       ← Proyecto Wails (usa symlinks)"
echo -e "  ${GREEN}./dev.sh${NC}           ← Desarrollo con hot-reload"
echo -e "  ${GREEN}./build.sh${NC}         ← Compilación para Linux"
echo ""

echo -e "${CYAN}${BOLD}Próximos pasos:${NC}"
echo -e "  ${GREEN}1.${NC} ./dev.sh              ${GRAY}# Iniciar desarrollo${NC}"
echo -e "  ${GREEN}2.${NC} ./build.sh            ${GRAY}# Compilar para Linux${NC}"
echo ""

echo -e "${CYAN}${BOLD}Arquitectura:${NC}"
echo -e "  ${YELLOW}→${NC} Frontend y backend ${BOLD}no se copian${NC} a wails-app"
echo -e "  ${YELLOW}→${NC} Se usan ${BOLD}enlaces simbólicos${NC} (symlinks)"
echo -e "  ${YELLOW}→${NC} Cambios se reflejan ${BOLD}automáticamente${NC}"
echo ""

success "🎉 ¡Todo listo para desarrollar con Wails!"
