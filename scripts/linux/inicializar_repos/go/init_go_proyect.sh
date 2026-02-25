#!/bin/bash

# Script: Inicializa un repositorio Go completo en la ruta actual
# Genera estructura estándar, scripts de build/test y archivos base

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

show_header "Inicializador de Repo Go Completo 🐹" "Estructura profesional + scripts de desarrollo"

DEFAULT_PROJECT_NAME="go-project"
DEFAULT_MODULE="github.com/$(whoami)/$DEFAULT_PROJECT_NAME"
FORCE_OVERWRITE="${DL_FORCE_OVERWRITE:-0}"

PROJECT_NAME="${DL_PROJECT_NAME:-}"
MODULE_NAME="${DL_GO_MODULE:-}"

if [ -z "$PROJECT_NAME" ]; then
	if [ -t 0 ]; then
		read -r -p "Nombre del proyecto [$DEFAULT_PROJECT_NAME]: " PROJECT_NAME
	else
		warning "Entrada no interactiva detectada, usando nombre por defecto: $DEFAULT_PROJECT_NAME"
	fi
fi
PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}"

if [ -z "$MODULE_NAME" ]; then
	default_module_for_project="github.com/$(whoami)/$PROJECT_NAME"
	if [ -t 0 ]; then
		read -r -p "Módulo Go (go.mod) [$default_module_for_project]: " MODULE_NAME
	else
		warning "Entrada no interactiva detectada, usando módulo por defecto: $default_module_for_project"
	fi
fi
MODULE_NAME="${MODULE_NAME:-github.com/$(whoami)/$PROJECT_NAME}"

TARGET_DIR="$(pwd)/$PROJECT_NAME"

info "Proyecto: ${BOLD}$PROJECT_NAME${NC}"
info "Módulo: ${BOLD}$MODULE_NAME${NC}"
info "Ubicación: $TARGET_DIR"
echo ""

progress "Verificando dependencias..."
check_command "go" "GO_NOT_FOUND" || exit 1
check_command "git" "GIT_NOT_FOUND" || exit 1
show_version "go" "version"
echo ""

if [ -d "$PROJECT_NAME" ]; then
    warning "El directorio '$PROJECT_NAME' ya existe"
    echo ""

	if [ "$FORCE_OVERWRITE" = "1" ]; then
		progress "DL_FORCE_OVERWRITE=1 detectado, se eliminará el directorio automáticamente..."
	else
		if [ -t 0 ]; then
			if ! confirm "¿Deseas eliminarlo y crearlo de nuevo?" "n"; then
				info "Inicialización cancelada"
				exit 0
			fi
		else
			handle_error "DIRECTORY_ALREADY_EXISTS" "El directorio '$PROJECT_NAME' ya existe y no hay entrada interactiva" \
				"Usa DL_FORCE_OVERWRITE=1 para reemplazarlo o DL_PROJECT_NAME para otro nombre"
			exit 1
		fi
    fi

    progress "Eliminando directorio existente..."
    rm -rf "$PROJECT_NAME"
    success "Directorio eliminado"
    echo ""
fi

progress "Creando estructura de carpetas..."
mkdir -p "$PROJECT_NAME"/{cmd/app,internal/config,internal/service,pkg/version,scripts,bin}
cd "$PROJECT_NAME"
success "Estructura base creada"
echo ""

progress "Inicializando módulo Go..."
if ! go mod init "$MODULE_NAME"; then
    handle_error "GO_MOD_INIT_FAILED" "No se pudo inicializar el módulo Go" \
        "Verifica que el nombre del módulo sea válido"
    exit 1
fi
success "go.mod generado"
echo ""

progress "Creando archivos fuente..."

cat > cmd/app/main.go << 'EOF'
package main

import (
	"fmt"

	"REPLACE_MODULE/internal/config"
	"REPLACE_MODULE/internal/service"
	"REPLACE_MODULE/pkg/version"
)

func main() {
	cfg := config.Load()
	msg := service.BuildStartupMessage(cfg.AppName, version.Current())

	fmt.Println(msg)
}
EOF

cat > internal/config/config.go << 'EOF'
package config

import "os"

type AppConfig struct {
	AppName string
}

func Load() AppConfig {
	appName := os.Getenv("APP_NAME")
	if appName == "" {
		appName = "Go Project"
	}

	return AppConfig{AppName: appName}
}
EOF

cat > internal/service/message.go << 'EOF'
package service

import "fmt"

func BuildStartupMessage(appName, appVersion string) string {
	return fmt.Sprintf("🚀 %s iniciado correctamente (version %s)", appName, appVersion)
}
EOF

cat > internal/service/message_test.go << 'EOF'
package service

import "testing"

func TestBuildStartupMessage(t *testing.T) {
	result := BuildStartupMessage("DevLauncher", "0.1.0")
	want := "🚀 DevLauncher iniciado correctamente (version 0.1.0)"

	if result != want {
		t.Fatalf("resultado inesperado:\nwant: %s\ngot:  %s", want, result)
	}
}
EOF

cat > pkg/version/version.go << 'EOF'
package version

var value = "0.1.0"

func Current() string {
	return value
}
EOF

cat > Makefile << 'EOF'
APP_NAME=app
CMD_PATH=./cmd/app
BIN_DIR=./bin

.PHONY: run build build-all test fmt tidy clean

run:
	go run $(CMD_PATH)

build:
	mkdir -p $(BIN_DIR)
	go build -o $(BIN_DIR)/$(APP_NAME) $(CMD_PATH)

build-all:
	bash ./scripts/build-all.sh

test:
	go test ./...

fmt:
	gofmt -w ./cmd ./internal ./pkg

tidy:
	go mod tidy

clean:
	rm -rf $(BIN_DIR)
EOF

cat > .gitignore << 'EOF'
# Binarios
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test / cobertura
*.test
*.out
coverage.out

# IDE / editor
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

cat > README.md << 'EOF'
# GO_PROJECT_NAME

Repositorio Go inicializado automáticamente con estructura completa.

## 📁 Estructura

```
GO_PROJECT_NAME/
├── cmd/app/main.go
├── internal/
│   ├── config/config.go
│   └── service/
│       ├── message.go
│       └── message_test.go
├── pkg/version/version.go
├── scripts/
│   ├── build.sh
│   ├── build-all.sh
│   ├── run.sh
│   ├── test.sh
│   └── lint.sh
├── bin/
├── Makefile
├── go.mod
├── .gitignore
└── README.md
```

## 🚀 Uso rápido

```bash
./scripts/run.sh
./scripts/test.sh
./scripts/build.sh
./scripts/build-all.sh
```

## 🧰 Comandos con Make

```bash
make run
make test
make build
make build-all
make fmt
make tidy
```
EOF

cat > scripts/run.sh << 'EOF'
#!/bin/bash
set -euo pipefail

go run ./cmd/app
EOF

cat > scripts/test.sh << 'EOF'
#!/bin/bash
set -euo pipefail

go test ./...
EOF

cat > scripts/lint.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "→ Ejecutando gofmt en modo verificación"
unformatted="$(gofmt -l ./cmd ./internal ./pkg)"

if [ -n "$unformatted" ]; then
    echo "✗ Archivos sin formato:" >&2
    echo "$unformatted" >&2
    echo "Ejecuta: make fmt" >&2
    exit 1
fi

echo "✓ Formato OK"
EOF

cat > scripts/build.sh << 'EOF'
#!/bin/bash
set -euo pipefail

mkdir -p ./bin
go build -o ./bin/app ./cmd/app
echo "✓ Binario generado: ./bin/app"
EOF

cat > scripts/build-all.sh << 'EOF'
#!/bin/bash
set -euo pipefail

mkdir -p ./bin

GOOS=linux GOARCH=amd64 go build -o ./bin/app-linux-amd64 ./cmd/app
GOOS=darwin GOARCH=amd64 go build -o ./bin/app-darwin-amd64 ./cmd/app
GOOS=windows GOARCH=amd64 go build -o ./bin/app-windows-amd64.exe ./cmd/app

echo "✓ Builds generados en ./bin"
EOF

sed -i "s|REPLACE_MODULE|$MODULE_NAME|g" cmd/app/main.go
sed -i "s|GO_PROJECT_NAME|$PROJECT_NAME|g" README.md

chmod +x scripts/*.sh

progress "Ajustando dependencias..."
go mod tidy
success "Dependencias ajustadas"
echo ""

progress "Inicializando repositorio git..."
git init >/dev/null 2>&1
git add .
success "Repositorio git inicializado"
echo ""

echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
success "✅ ¡Repositorio Go creado exitosamente!"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "Próximos pasos:"
echo -e "  ${GREEN}1.${NC} cd $PROJECT_NAME"
echo -e "  ${GREEN}2.${NC} ./scripts/run.sh"
echo -e "  ${GREEN}3.${NC} ./scripts/test.sh"
echo -e "  ${GREEN}4.${NC} ./scripts/build-all.sh"
echo ""

success "🎉 Proyecto listo para empezar"
