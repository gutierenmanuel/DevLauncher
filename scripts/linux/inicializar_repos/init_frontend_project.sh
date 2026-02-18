#!/bin/bash

# Script para inicializar un proyecto frontend con React, Vite, Tailwind y pnpm

set -e

# Si no se proporciona nombre, usar "frontend"
PROJECT_NAME="${1:-frontend}"

echo "🚀 Inicializando proyecto frontend: $PROJECT_NAME"
echo "   Stack: React + Vite + Tailwind CSS + pnpm"
echo ""

# Verificar que pnpm esté instalado
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm no está instalado"
    echo "   Instálalo con: ./scripts/instaladores/instalar_pnpm.sh"
    exit 1
fi

# Crear proyecto con Vite
echo "📦 Creando proyecto con Vite..."
pnpm create vite $PROJECT_NAME --template react

cd $PROJECT_NAME

# Instalar dependencias
echo "📥 Instalando dependencias..."
pnpm install

# Instalar Tailwind CSS y dependencias
echo "🎨 Instalando Tailwind CSS..."
pnpm install -D tailwindcss postcss autoprefixer
pnpm exec tailwindcss init -p

# Configurar Tailwind
echo "⚙️  Configurando Tailwind CSS..."
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
echo "✅ Proyecto frontend creado exitosamente!"
echo ""
echo "📁 Ubicación: ./$PROJECT_NAME"
echo ""
echo "Próximos pasos:"
echo "  1. cd $PROJECT_NAME"
echo "  2. pnpm dev"
echo "  3. Abre http://localhost:5173 en tu navegador"
