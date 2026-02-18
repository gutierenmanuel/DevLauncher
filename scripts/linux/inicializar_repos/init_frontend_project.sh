#!/bin/bash

# Script para inicializar un proyecto frontend con React, Vite, Tailwind y pnpm

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# Si no se proporciona nombre, usar "frontend"
PROJECT_NAME="${1:-frontend}"

show_header "Inicializador de Proyecto Frontend 🆕" "React + Vite + Tailwind + pnpm"

info "Proyecto: ${BOLD}$PROJECT_NAME${NC}"
echo ""

# Verificar que pnpm esté instalado
progress "Verificando dependencias..."
check_command "pnpm" "PNPM_NOT_FOUND" || exit 1
show_version "pnpm" "--version"
echo ""

# Verificar si el directorio ya existe
if [ -d "$PROJECT_NAME" ]; then
    handle_error "DIRECTORY_EXISTS" "El directorio '$PROJECT_NAME' ya existe" \
        "Usa otro nombre o elimina el directorio existente"
    exit 1
fi

# Crear proyecto con Vite
progress "📦 Creando proyecto con Vite..."
if ! pnpm create vite $PROJECT_NAME --template react; then
    handle_error "PROJECT_INIT_FAILED" "Falló la creación del proyecto con Vite" \
        "Verifica tu conexión a internet"
    exit 1
fi

cd $PROJECT_NAME || exit 1

# Instalar dependencias
progress "📥 Instalando dependencias base..."
if ! pnpm install; then
    cd ..
    handle_error "NPM_INSTALL_FAILED" "Falló la instalación de dependencias" \
        "Verifica tu conexión a internet"
    exit 1
fi

# Instalar Tailwind CSS y dependencias
progress "🎨 Instalando Tailwind CSS..."
if ! pnpm install -D tailwindcss postcss autoprefixer; then
    cd ..
    handle_error "NPM_INSTALL_FAILED" "Falló la instalación de Tailwind" \
        "Verifica tu conexión a internet"
    exit 1
fi

progress "⚙️  Inicializando Tailwind CSS..."
if ! pnpm exec tailwindcss init -p; then
    cd ..
    handle_error "TAILWIND_INIT_FAILED" "Falló la inicialización de Tailwind" \
        "Puede que ya esté inicializado"
fi

# Configurar Tailwind
progress "📝 Configurando Tailwind CSS..."
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Crear archivo CSS con directivas de Tailwind
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# Actualizar App.jsx con ejemplo usando Tailwind
cat > src/App.jsx << 'EOF'
import { useState } from 'react'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
      <div className="bg-white p-8 rounded-2xl shadow-xl max-w-md w-full">
        <h1 className="text-4xl font-bold text-gray-800 mb-4 text-center">
          ¡Hola desde React! 👋
        </h1>
        <p className="text-gray-600 mb-6 text-center">
          Vite + React + Tailwind CSS
        </p>
        
        <div className="flex flex-col items-center gap-4">
          <button
            onClick={() => setCount((count) => count + 1)}
            className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-6 rounded-lg transition duration-200 transform hover:scale-105"
          >
            Contador: {count}
          </button>
          
          <p className="text-sm text-gray-500">
            Edita <code className="bg-gray-100 px-2 py-1 rounded">src/App.jsx</code> para ver los cambios
          </p>
        </div>
      </div>
    </div>
  )
}

export default App
EOF

# Crear README personalizado
cat > README.md << EOF
# $PROJECT_NAME

Proyecto frontend inicializado con React, Vite, Tailwind CSS y pnpm.

## Stack

- ⚡ **Vite** - Build tool ultra rápido
- ⚛️ **React** - Biblioteca UI
- 🎨 **Tailwind CSS** - Framework CSS utility-first
- 📦 **pnpm** - Gestor de paquetes eficiente

## Desarrollo

\`\`\`bash
# Instalar dependencias
pnpm install

# Iniciar servidor de desarrollo
pnpm dev

# Build para producción
pnpm build

# Preview del build
pnpm preview
\`\`\`

## Estructura del proyecto

\`\`\`
.
├── src/
│   ├── App.jsx          # Componente principal
│   ├── main.jsx         # Punto de entrada
│   └── index.css        # Estilos con Tailwind
├── public/              # Archivos estáticos
├── index.html           # HTML principal
├── vite.config.js       # Configuración de Vite
├── tailwind.config.js   # Configuración de Tailwind
└── package.json         # Dependencias y scripts
\`\`\`

## Scripts disponibles

- \`pnpm dev\` - Inicia el servidor de desarrollo
- \`pnpm build\` - Construye para producción
- \`pnpm preview\` - Preview del build de producción
- \`pnpm lint\` - Ejecuta el linter

## Recursos

- [Vite](https://vitejs.dev/)
- [React](https://react.dev/)
- [Tailwind CSS](https://tailwindcss.com/)
- [pnpm](https://pnpm.io/)
EOF

# Agregar más scripts útiles al package.json
pnpm pkg set scripts.format="prettier --write \"src/**/*.{js,jsx,ts,tsx,json,css,md}\""

echo ""
success "✅ Proyecto frontend creado exitosamente!"
echo ""
info "📁 Ubicación: ./$PROJECT_NAME"
echo ""
echo -e "${CYAN}Próximos pasos:${NC}"
echo -e "  ${GREEN}1.${NC} cd $PROJECT_NAME"
echo -e "  ${GREEN}2.${NC} pnpm dev"
echo -e "  ${GREEN}3.${NC} Abre http://localhost:5173 en tu navegador"
echo ""
success "🎉 ¡Listo para desarrollar!"
