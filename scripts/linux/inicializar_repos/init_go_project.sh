#!/bin/bash

# Script para inicializar un proyecto de Go en la carpeta actual

set -e

# Si no se proporciona nombre, usar el nombre de la carpeta actual
DEFAULT_NAME=$(basename "$PWD")
PROJECT_NAME="${1:-$DEFAULT_NAME}"

echo "🚀 Inicializando proyecto Go: $PROJECT_NAME"

# Crear estructura de directorios
mkdir -p cmd/$PROJECT_NAME
mkdir -p internal
mkdir -p pkg
mkdir -p api
mkdir -p configs
mkdir -p scripts
mkdir -p test

# Inicializar go module
echo "📦 Inicializando go module..."
go mod init $PROJECT_NAME

# Crear main.go
cat > cmd/$PROJECT_NAME/main.go << 'EOF'
package main

import (
	"fmt"
)

func main() {
	fmt.Println("¡Hola desde Go!")
}
EOF

# Crear README.md
cat > README.md << EOF
# $PROJECT_NAME

Proyecto Go inicializado con estructura estándar.

## Estructura del proyecto

\`\`\`
.
├── cmd/              # Aplicaciones principales
├── internal/         # Código privado de la aplicación
├── pkg/             # Librerías que pueden ser usadas por otras aplicaciones
├── api/             # Definiciones de API (OpenAPI, Protocol Buffers, etc.)
├── configs/         # Archivos de configuración
├── scripts/         # Scripts de build, install, análisis, etc.
└── test/            # Pruebas y datos de prueba
\`\`\`

## Ejecutar

\`\`\`bash
go run cmd/$PROJECT_NAME/main.go
\`\`\`

## Construir

\`\`\`bash
go build -o bin/$PROJECT_NAME cmd/$PROJECT_NAME/main.go
\`\`\`
EOF

# Crear .gitignore
cat > .gitignore << 'EOF'
# Binarios
*.exe
*.exe~
*.dll
*.so
*.dylib
bin/
dist/

# Archivos de test
*.test
*.out
coverage.txt
*.prof

# Dependencias
vendor/

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

# Crear Makefile
cat > Makefile << EOF
.PHONY: run build test clean

run:
	go run cmd/$PROJECT_NAME/main.go

build:
	go build -o bin/$PROJECT_NAME cmd/$PROJECT_NAME/main.go

test:
	go test -v ./...

clean:
	rm -rf bin/
	go clean
EOF

echo "✅ Proyecto Go creado exitosamente!"
echo ""
echo "Próximos pasos:"
echo "  1. cd a tu directorio de proyecto"
echo "  2. go mod tidy"
echo "  3. make run"
