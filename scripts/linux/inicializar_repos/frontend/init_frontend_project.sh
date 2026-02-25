#!/bin/bash

# Script para inicializar un proyecto frontend completo
# Stack: React + Vite + Tailwind CSS + shadcn/ui + Storybook + pnpm

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# Nombre fijo del proyecto
PROJECT_NAME="frontend"

show_header "Inicializador de Proyecto Frontend Completo 🚀" "React + Vite + Tailwind + shadcn/ui + Storybook"

info "Proyecto: ${BOLD}$PROJECT_NAME${NC}"
info "Ubicación: $(pwd)/$PROJECT_NAME"
echo ""

# Verificar que pnpm esté instalado
progress "Verificando dependencias..."
check_command "pnpm" "PNPM_NOT_FOUND" || exit 1
show_version "pnpm" "--version"
echo ""

# Pedir sudo por adelantado (Storybook/Playwright necesita instalar dependencias del sistema)
if [ "$(uname)" != "Darwin" ] && [ "$EUID" -ne 0 ]; then
    info "Se necesitan permisos de administrador para instalar dependencias de Playwright"
    if ! sudo -v 2>/dev/null; then
        warning "No se pudo obtener sudo. Playwright podría fallar al instalar browsers."
    else
        # Mantener sudo activo en segundo plano
        (while true; do sudo -n true; sleep 50; done) 2>/dev/null &
        SUDO_KEEPALIVE_PID=$!
        trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null; error "El script falló en la línea $LINENO"' ERR EXIT
        success "Permisos de administrador obtenidos"
    fi
    echo ""
fi

# Verificar si el directorio ya existe
if [ -d "$PROJECT_NAME" ]; then
    warning "El directorio '$PROJECT_NAME' ya existe"
    echo ""
    
    if ! confirm "¿Deseas eliminarlo y crear uno nuevo?" "n"; then
        info "Instalación cancelada"
        exit 0
    fi
    
    progress "Eliminando directorio existente..."
    rm -rf "$PROJECT_NAME"
    success "Directorio eliminado"
    echo ""
fi

# ==========================================
# 1. CREAR PROYECTO VITE + REACT
# ==========================================
progress "📦 Creando proyecto con Vite + React..."
if ! pnpm create vite@latest $PROJECT_NAME --template react-ts <<< ""; then
    handle_error "PROJECT_INIT_FAILED" "Falló la creación del proyecto con Vite" \
        "Verifica tu conexión a internet"
    exit 1
fi
success "Proyecto Vite creado"
echo ""

cd $PROJECT_NAME || exit 1

# ==========================================
# 2. INSTALAR DEPENDENCIAS BASE
# ==========================================
progress "📥 Instalando dependencias base..."
if ! pnpm install; then
    cd ..
    handle_error "NPM_INSTALL_FAILED" "Falló la instalación de dependencias" \
        "Verifica tu conexión a internet"
    exit 1
fi
success "Dependencias base instaladas"
echo ""

# ==========================================
# 3. INSTALAR Y CONFIGURAR TAILWIND CSS
# ==========================================
progress "🎨 Instalando Tailwind CSS..."
if ! pnpm install -D tailwindcss postcss autoprefixer; then
    cd ..
    handle_error "NPM_INSTALL_FAILED" "Falló la instalación de Tailwind" \
        "Verifica tu conexión a internet"
    exit 1
fi

progress "⚙️  Inicializando Tailwind CSS..."
if ! pnpm exec tailwindcss init -p; then
    warning "Tailwind ya podría estar inicializado"
fi
success "Tailwind CSS instalado"
echo ""

# Configurar Tailwind
progress "📝 Configurando Tailwind CSS..."
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ["class"],
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      colors: {},
    },
  },
  plugins: [require("tailwindcss-animate")],
}
EOF

# Crear archivo CSS con directivas de Tailwind
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF

success "Tailwind CSS configurado"
echo ""

# ==========================================
# 4. INSTALAR SHADCN/UI
# ==========================================
progress "🎨 Instalando shadcn/ui..."

# Instalar dependencias necesarias para shadcn
if ! pnpm install -D tailwindcss-animate class-variance-authority clsx tailwind-merge; then
    cd ..
    handle_error "NPM_INSTALL_FAILED" "Falló la instalación de dependencias de shadcn"
    exit 1
fi

# Instalar lucide-react para iconos
if ! pnpm install lucide-react; then
    cd ..
    handle_error "NPM_INSTALL_FAILED" "Falló la instalación de lucide-react"
    exit 1
fi

# Crear archivo de utilidades para cn()
mkdir -p src/lib
cat > src/lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF

# Crear components.json para shadcn
cat > components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
EOF

# Actualizar tsconfig.json para path aliases
cat > tsconfig.json << 'EOF'
{
  "files": [],
  "references": [
    { "path": "./tsconfig.app.json" },
    { "path": "./tsconfig.node.json" }
  ],
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
EOF

# Actualizar tsconfig.app.json
cat > tsconfig.app.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"]
}
EOF

# Actualizar vite.config para resolver @ alias
cat > vite.config.ts << 'EOF'
import path from "path"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
EOF

# Instalar @types/node para path
pnpm install -D @types/node

success "shadcn/ui configurado (usa: pnpx shadcn@latest add <componente>)"
echo ""

# ==========================================
# 5. INSTALAR Y CONFIGURAR STORYBOOK
# ==========================================
progress "📚 Instalando Storybook..."
info "Esto puede tomar unos minutos..."
echo ""

# Inicializar Storybook (modo no interactivo)
if ! pnpm dlx storybook@latest init --skip-install --yes; then
    warning "Storybook init falló, intentando instalación manual..."
    
    # Instalación manual de Storybook
    pnpm install -D @storybook/react-vite @storybook/react @storybook/blocks \
        @storybook/addon-essentials @storybook/addon-interactions \
        @storybook/test storybook
fi

# Instalar dependencias si no se instalaron
progress "Instalando dependencias de Storybook..."
pnpm install

success "Storybook instalado"
echo ""

# Crear historia de ejemplo con shadcn button
mkdir -p src/components/ui
cat > src/components/ui/button.tsx << 'EOF'
import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground hover:bg-primary/90",
        destructive:
          "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline:
          "border border-input bg-background hover:bg-accent hover:text-accent-foreground",
        secondary:
          "bg-secondary text-secondary-foreground hover:bg-secondary/80",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-10 px-4 py-2",
        sm: "h-9 rounded-md px-3",
        lg: "h-11 rounded-md px-8",
        icon: "h-10 w-10",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
EOF

# Crear historia para el botón
mkdir -p src/stories
cat > src/stories/Button.stories.tsx << 'EOF'
import type { Meta, StoryObj } from '@storybook/react'
import { Button } from '@/components/ui/button'

const meta = {
  title: 'UI/Button',
  component: Button,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
} satisfies Meta<typeof Button>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    children: 'Button',
  },
}

export const Destructive: Story = {
  args: {
    variant: 'destructive',
    children: 'Destructive',
  },
}

export const Outline: Story = {
  args: {
    variant: 'outline',
    children: 'Outline',
  },
}

export const Secondary: Story = {
  args: {
    variant: 'secondary',
    children: 'Secondary',
  },
}

export const Ghost: Story = {
  args: {
    variant: 'ghost',
    children: 'Ghost',
  },
}

export const Link: Story = {
  args: {
    variant: 'link',
    children: 'Link',
  },
}

export const Large: Story = {
  args: {
    size: 'lg',
    children: 'Large Button',
  },
}

export const Small: Story = {
  args: {
    size: 'sm',
    children: 'Small Button',
  },
}
EOF

success "Storybook configurado con componente de ejemplo"
echo ""

# ==========================================
# 6. CREAR APP.TSX DE EJEMPLO
# ==========================================
progress "🎨 Creando aplicación de ejemplo..."

cat > src/App.tsx << 'EOF'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 flex items-center justify-center p-4">
      <div className="bg-white dark:bg-gray-800 p-8 rounded-2xl shadow-xl max-w-2xl w-full">
        <h1 className="text-4xl font-bold text-gray-800 dark:text-white mb-4 text-center">
          ¡Hola desde React! 👋
        </h1>
        <p className="text-gray-600 dark:text-gray-300 mb-6 text-center">
          Vite + React + TypeScript + Tailwind CSS + shadcn/ui + Storybook
        </p>
        
        <div className="flex flex-col items-center gap-6">
          <div className="flex gap-2 flex-wrap justify-center">
            <Button onClick={() => setCount((count) => count + 1)}>
              Contador: {count}
            </Button>
            <Button variant="secondary" onClick={() => setCount(0)}>
              Reset
            </Button>
            <Button variant="outline">Outline</Button>
            <Button variant="ghost">Ghost</Button>
          </div>
          
          <div className="bg-gray-50 dark:bg-gray-700 p-4 rounded-lg">
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">
              ✨ <strong>shadcn/ui</strong> componentes incluidos
            </p>
            <p className="text-sm text-gray-600 dark:text-gray-300">
              📚 <strong>Storybook</strong> configurado (ejecuta: <code className="bg-gray-200 dark:bg-gray-600 px-2 py-1 rounded">pnpm storybook</code>)
            </p>
          </div>
          
          <p className="text-sm text-gray-500 dark:text-gray-400 text-center">
            Edita <code className="bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">src/App.tsx</code> para ver los cambios
          </p>
        </div>
      </div>
    </div>
  )
}

export default App
EOF

cat > src/App.css << 'EOF'
#root {
  width: 100%;
  margin: 0;
  padding: 0;
}
EOF

success "App de ejemplo creada"
echo ""

# ==========================================
# 7. CREAR README COMPLETO
# ==========================================
progress "📝 Generando README..."

cat > README.md << 'EOF'
# Frontend Project

Proyecto frontend moderno con el mejor stack de desarrollo.

## 🚀 Stack Tecnológico

- ⚡ **Vite** - Build tool ultra rápido
- ⚛️ **React 18** - Biblioteca UI
- 🔷 **TypeScript** - Tipado estático
- 🎨 **Tailwind CSS** - Framework CSS utility-first
- 🎭 **shadcn/ui** - Componentes UI de alta calidad
- 📚 **Storybook** - Documentación de componentes
- 📦 **pnpm** - Gestor de paquetes eficiente

## 📦 Instalación

Las dependencias ya están instaladas. Si necesitas reinstalar:

```bash
pnpm install
```

## 🛠️ Desarrollo

### Iniciar servidor de desarrollo (opción recomendada)

Usa el script `dev.sh` creado en la raíz:

```bash
./dev.sh
```

### Opción alternativa (manual)

```bash
cd frontend
pnpm dev
```

Abre [http://localhost:5173](http://localhost:5173) en tu navegador.

### Iniciar Storybook

```bash
pnpm storybook
```

Abre [http://localhost:6006](http://localhost:6006) para ver la documentación de componentes.

## 🎨 Agregar Componentes de shadcn/ui

shadcn/ui está configurado. Para agregar componentes:

```bash
# Agregar un componente
pnpx shadcn@latest add button
pnpx shadcn@latest add card
pnpx shadcn@latest add input

# Ver componentes disponibles
pnpx shadcn@latest add
```

Los componentes se agregarán en `src/components/ui/`

## 📚 Crear Historias de Storybook

Crea archivos `.stories.tsx` en `src/stories/`:

```typescript
import type { Meta, StoryObj } from '@storybook/react'
import { MiComponente } from '@/components/MiComponente'

const meta = {
  title: 'Components/MiComponente',
  component: MiComponente,
  parameters: { layout: 'centered' },
  tags: ['autodocs'],
} satisfies Meta<typeof MiComponente>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    // props del componente
  },
}
```

## 🏗️ Build para Producción

```bash
pnpm build
```

Los archivos optimizados estarán en `dist/`

### Preview del build

```bash
pnpm preview
```

## 📁 Estructura del Proyecto

```
.
├── src/
│   ├── components/
│   │   └── ui/              # Componentes shadcn/ui
│   ├── lib/
│   │   └── utils.ts         # Utilidades (cn, etc.)
│   ├── stories/             # Historias de Storybook
│   ├── App.tsx              # Componente principal
│   ├── main.tsx             # Punto de entrada
│   └── index.css            # Estilos globales + Tailwind
├── .storybook/              # Configuración de Storybook
├── public/                  # Archivos estáticos
├── index.html               # HTML principal
├── vite.config.ts           # Configuración de Vite
├── tailwind.config.js       # Configuración de Tailwind
├── components.json          # Configuración de shadcn/ui
└── package.json             # Dependencias y scripts

## 🎯 Scripts Disponibles

- `pnpm dev` - Servidor de desarrollo
- `pnpm build` - Build de producción
- `pnpm preview` - Preview del build
- `pnpm lint` - Ejecutar ESLint
- `pnpm storybook` - Iniciar Storybook
- `pnpm build-storybook` - Build de Storybook

## 🎨 Temas y Personalización

### Cambiar tema de shadcn/ui

Edita `src/index.css` para personalizar las variables CSS:

```css
:root {
  --primary: 222.2 47.4% 11.2%;
  --radius: 0.5rem;
  /* ... más variables */
}
```

### Modo oscuro

El proyecto ya tiene soporte para modo oscuro. Usa:

```tsx
<html className="dark">
```

## 📖 Recursos

- [Vite](https://vitejs.dev/)
- [React](https://react.dev/)
- [TypeScript](https://www.typescriptlang.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [shadcn/ui](https://ui.shadcn.com/)
- [Storybook](https://storybook.js.org/)
- [pnpm](https://pnpm.io/)

## 💡 Tips

### Agregar más componentes

```bash
# Ver todos los componentes disponibles
pnpx shadcn@latest add

# Algunos útiles
pnpx shadcn@latest add card dialog toast
```

### Usar iconos

El proyecto incluye `lucide-react`:

```tsx
import { Heart, Star, Check } from 'lucide-react'

<Heart className="w-6 h-6" />
```

### Alias de imports

Usa `@/` para imports absolutos:

```tsx
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
```
EOF

success "README generado"
echo ""

# ==========================================
# 8. AGREGAR SCRIPTS ÚTILES
# ==========================================
progress "⚙️  Configurando scripts adicionales..."

pnpm pkg set scripts.format="prettier --write \"src/**/*.{ts,tsx,json,css,md}\""

success "Scripts configurados"
echo ""

# ==========================================
# 9. CREAR SCRIPT DEV.SH EN LA RAÍZ
# ==========================================
progress "🚀 Creando script dev.sh en la raíz del proyecto..."

cd ..

cat > dev.sh << 'EOF'
#!/bin/bash

# Script de desarrollo para proyecto frontend
# Inicia el servidor de desarrollo con Vite

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║   Frontend Development Server 🚀                          ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "frontend" ]; then
    echo -e "${RED}✗ No se encuentra el directorio 'frontend'${NC}"
    echo -e "${YELLOW}  Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
fi

cd frontend

# Verificar que pnpm esté instalado
if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}✗ pnpm no está instalado${NC}"
    echo -e "${YELLOW}  Instálalo con: npm install -g pnpm${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Directorio frontend encontrado${NC}"
echo -e "${GREEN}✓ pnpm instalado${NC}"
echo ""

# Verificar dependencias
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}→ Instalando dependencias...${NC}"
    pnpm install
    echo ""
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Iniciando servidor de desarrollo...${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}🔥 Hot-Reload activado${NC}"
echo -e "${GREEN}📦 Stack: React + Vite + TypeScript + Tailwind + shadcn/ui${NC}"
echo ""
echo -e "${YELLOW}→ URL: http://localhost:5173${NC}"
echo ""
echo -e "${PURPLE}Presiona Ctrl+C para detener${NC}"
echo ""

# Iniciar Vite
pnpm dev
EOF

chmod +x dev.sh

success "Script dev.sh creado en la raíz del proyecto"
echo ""

# ==========================================
# FINALIZACIÓN
# ==========================================

echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
success "✅ ¡Proyecto frontend completo creado exitosamente!"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""

info "📁 Ubicación: ./$PROJECT_NAME"
echo ""

echo -e "${CYAN}${BOLD}Stack instalado:${NC}"
echo -e "  ${GREEN}✓${NC} React 18 + TypeScript"
echo -e "  ${GREEN}✓${NC} Vite (build tool)"
echo -e "  ${GREEN}✓${NC} Tailwind CSS"
echo -e "  ${GREEN}✓${NC} shadcn/ui (componentes)"
echo -e "  ${GREEN}✓${NC} Storybook (documentación)"
echo ""

echo -e "${CYAN}${BOLD}Próximos pasos:${NC}"
echo -e "  ${GREEN}1.${NC} ./dev.sh           ${GRAY}# Iniciar servidor de desarrollo${NC}"
echo -e "  ${GREEN}2.${NC} cd $PROJECT_NAME && pnpm storybook  ${GRAY}# Ver componentes${NC}"
echo ""
echo -e "${CYAN}${BOLD}Comandos alternativos:${NC}"
echo -e "  ${GREEN}→${NC} cd $PROJECT_NAME && pnpm dev      ${GRAY}# Desarrollo manual${NC}"
echo -e "  ${GREEN}→${NC} cd $PROJECT_NAME && pnpm build    ${GRAY}# Build producción${NC}"
echo ""

echo -e "${CYAN}${BOLD}Agregar componentes de shadcn/ui:${NC}"
echo -e "  ${GREEN}→${NC} pnpx shadcn@latest add button"
echo -e "  ${GREEN}→${NC} pnpx shadcn@latest add card"
echo -e "  ${GREEN}→${NC} pnpx shadcn@latest add dialog"
echo ""

success "🎉 ¡Todo listo para desarrollar!"
