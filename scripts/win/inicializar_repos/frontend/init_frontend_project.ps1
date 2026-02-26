# Script para inicializar un proyecto frontend completo en Windows
# Stack: React + Vite + Tailwind CSS + shadcn/ui + Storybook + pnpm

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$Cyan = "`e[36m"
$Gray = "`e[90m"
$Bold = "`e[1m"
$NC = "`e[0m"

$ErrorActionPreference = "Stop"

# Nombre fijo del proyecto
$PROJECT_NAME = "frontend"

function Show-Header {
    param([string]$Title, [string]$Subtitle = "")
    Write-Host ""
    Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
    $titlePadded = "  $Title" + (" " * (57 - $Title.Length))
    Write-Host "${Purple}║${NC}$titlePadded${Purple}║${NC}"
    if ($Subtitle) {
        $subtitlePadded = "  $Subtitle" + (" " * (57 - $Subtitle.Length))
        Write-Host "${Purple}║${NC}$subtitlePadded${Purple}║${NC}"
    }
    Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
    Write-Host ""
}

Show-Header "Inicializador de Proyecto Frontend Completo 🚀" "React + Vite + Tailwind + shadcn/ui + Storybook"

Write-Host "${Blue}→ Proyecto: ${Bold}$PROJECT_NAME${NC}"
Write-Host "${Blue}→ Ubicación: $(Get-Location)\$PROJECT_NAME${NC}"
Write-Host ""

# Verificar que pnpm esté instalado
Write-Host "${Blue}→ Verificando dependencias...${NC}"
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "${Red}✗ pnpm no está instalado${NC}"
    Write-Host "${Yellow}Instálalo con: ${Cyan}devscript instalar_pnpm.ps1${NC}"
    exit 1
}

$pnpmVersion = & pnpm --version
Write-Host "${Green}✓ pnpm: $pnpmVersion${NC}"
Write-Host ""

# Verificar si el directorio ya existe
if (Test-Path $PROJECT_NAME) {
    Write-Host "${Yellow}⚠ El directorio '$PROJECT_NAME' ya existe${NC}"
    Write-Host ""
    $response = Read-Host "¿Deseas eliminarlo y crear uno nuevo? (s/n)"
    
    if ($response -notmatch '^[sS]$') {
        Write-Host "${Blue}Instalación cancelada${NC}"
        exit 0
    }
    
    Write-Host "${Blue}→ Eliminando directorio existente...${NC}"
    Remove-Item -Path $PROJECT_NAME -Recurse -Force
    Write-Host "${Green}✓ Directorio eliminado${NC}"
    Write-Host ""
}

# ==========================================
# 1. CREAR PROYECTO VITE + REACT
# ==========================================
Write-Host "${Blue}→ 📦 Creando proyecto con Vite + React...${NC}"

try {
    # Responder automáticamente: No a Vite 8 beta, No a instalar y arrancar
    $responses = "n`nn`n"
    $responses | & pnpm create vite $PROJECT_NAME --template react-ts
    if ($LASTEXITCODE -ne 0) { throw "Error al crear proyecto" }
} catch {
    Write-Host "${Red}✗ Falló la creación del proyecto con Vite${NC}"
    Write-Host "${Yellow}Verifica tu conexión a internet${NC}"
    exit 1
}

Write-Host "${Green}✓ Proyecto Vite creado${NC}"
Write-Host ""

Set-Location $PROJECT_NAME

# ==========================================
# 2. INSTALAR DEPENDENCIAS BASE
# ==========================================
Write-Host "${Blue}→ 📥 Instalando dependencias base...${NC}"

try {
    $output = & pnpm install 2>&1
    if ($LASTEXITCODE -ne 0) { 
        Write-Host $output
        throw "Error al instalar dependencias" 
    }
} catch {
    Set-Location ..
    Write-Host "${Red}✗ Falló la instalación de dependencias${NC}"
    exit 1
}

Write-Host "${Green}✓ Dependencias base instaladas${NC}"
Write-Host ""

# ==========================================
# 3. INSTALAR Y CONFIGURAR TAILWIND CSS
# ==========================================
Write-Host "${Blue}→ 🎨 Instalando Tailwind CSS...${NC}"

try {
    $output = & pnpm install -D tailwindcss postcss autoprefixer 2>&1
    if ($LASTEXITCODE -ne 0) { 
        Write-Host $output
        throw "Error al instalar Tailwind" 
    }
} catch {
    Set-Location ..
    Write-Host "${Red}✗ Falló la instalación de Tailwind${NC}"
    exit 1
}

Write-Host "${Blue}→ ⚙️  Inicializando Tailwind CSS...${NC}"
try {
    & pnpm exec tailwindcss init -p 2>$null | Out-Null
} catch {
    Write-Host "${Yellow}⚠ Continuando sin init de Tailwind (se configurará manualmente)${NC}"
}

Write-Host "${Green}✓ Tailwind CSS instalado${NC}"
Write-Host ""

# Configurar Tailwind
Write-Host "${Blue}→ 📝 Configurando Tailwind CSS...${NC}"

$tailwindConfig = @"
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
"@

$tailwindConfig | Out-File -FilePath "tailwind.config.js" -Encoding UTF8

# Crear archivo CSS con directivas de Tailwind
$indexCss = @"
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
"@

$indexCss | Out-File -FilePath "src\index.css" -Encoding UTF8

Write-Host "${Green}✓ Tailwind CSS configurado${NC}"
Write-Host ""

# ==========================================
# 4. INSTALAR SHADCN/UI
# ==========================================
Write-Host "${Blue}→ 🎨 Instalando shadcn/ui...${NC}"

try {
    $null = & pnpm install -D tailwindcss-animate class-variance-authority clsx tailwind-merge 2>&1
    $null = & pnpm install lucide-react 2>&1
} catch {
    Write-Host "${Yellow}⚠ Error al instalar dependencias de shadcn${NC}"
}

# Crear archivo de utilidades para cn()
New-Item -ItemType Directory -Path "src\lib" -Force | Out-Null

$utilsTs = @"
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
"@

$utilsTs | Out-File -FilePath "src\lib\utils.ts" -Encoding UTF8

# Crear components.json para shadcn
$componentsJson = @"
{
  "`$schema": "https://ui.shadcn.com/schema.json",
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
"@

$componentsJson | Out-File -FilePath "components.json" -Encoding UTF8

# Actualizar tsconfig.json para path aliases
$tsconfigJson = @"
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
"@

$tsconfigJson | Out-File -FilePath "tsconfig.json" -Encoding UTF8

# Actualizar tsconfig.app.json
$tsconfigAppJson = @"
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
"@

$tsconfigAppJson | Out-File -FilePath "tsconfig.app.json" -Encoding UTF8

# Actualizar vite.config para resolver @ alias
$viteConfig = @"
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
"@

$viteConfig | Out-File -FilePath "vite.config.ts" -Encoding UTF8

# Instalar @types/node para path
$null = & pnpm install -D "@types/node" 2>&1

Write-Host "${Green}✓ shadcn/ui configurado (usa: pnpx shadcn@latest add <componente>)${NC}"
Write-Host ""

# ==========================================
# 5. INSTALAR Y CONFIGURAR STORYBOOK
# ==========================================
Write-Host "${Blue}→ 📚 Instalando Storybook...${NC}"
Write-Host "${Yellow}Esto puede tomar unos minutos...${NC}"
Write-Host ""

try {
    # Responder automáticamente 'y' a cualquier prompt de Storybook
    $env:CI = "true"  # Variable de entorno para modo no interactivo
    $null = "y`n" | & pnpm dlx storybook@latest init --skip-install --yes 2>&1
    $env:CI = $null
} catch {
    Write-Host "${Yellow}⚠ Storybook init falló, instalando manualmente...${NC}"
    $null = & pnpm install -D "@storybook/react-vite" "@storybook/react" "@storybook/blocks" "@storybook/addon-essentials" "@storybook/addon-interactions" "@storybook/test" "storybook" 2>&1
}

Write-Host "${Blue}→ Instalando dependencias de Storybook...${NC}"
$null = & pnpm install 2>&1

Write-Host "${Green}✓ Storybook instalado${NC}"
Write-Host ""

# Crear componente Button de shadcn
Write-Host "${Blue}→ 🎨 Creando componentes de ejemplo...${NC}"

New-Item -ItemType Directory -Path "src\components\ui" -Force | Out-Null

$buttonTsx = @'
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
'@

$buttonTsx | Out-File -FilePath "src\components\ui\button.tsx" -Encoding UTF8

# Crear historia para el botón
New-Item -ItemType Directory -Path "src\stories" -Force | Out-Null

$buttonStories = @"
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
"@

$buttonStories | Out-File -FilePath "src\stories\Button.stories.tsx" -Encoding UTF8

Write-Host "${Green}✓ Storybook configurado con componente de ejemplo${NC}"
Write-Host ""

# ==========================================
# 6. CREAR APP.TSX DE EJEMPLO
# ==========================================
Write-Host "${Blue}→ 🎨 Creando aplicación de ejemplo...${NC}"

$appTsx = @"
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className=`"min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 flex items-center justify-center p-4`">
      <div className=`"bg-white dark:bg-gray-800 p-8 rounded-2xl shadow-xl max-w-2xl w-full`">
        <h1 className=`"text-4xl font-bold text-gray-800 dark:text-white mb-4 text-center`">
          ¡Hola desde React! 👋
        </h1>
        <p className=`"text-gray-600 dark:text-gray-300 mb-6 text-center`">
          Vite + React + TypeScript + Tailwind CSS + shadcn/ui + Storybook
        </p>
        
        <div className=`"flex flex-col items-center gap-6`">
          <div className=`"flex gap-2 flex-wrap justify-center`">
            <Button onClick={() => setCount((count) => count + 1)}>
              Contador: {count}
            </Button>
            <Button variant=`"secondary`" onClick={() => setCount(0)}>
              Reset
            </Button>
            <Button variant=`"outline`">Outline</Button>
            <Button variant=`"ghost`">Ghost</Button>
          </div>
          
          <div className=`"bg-gray-50 dark:bg-gray-700 p-4 rounded-lg`">
            <p className=`"text-sm text-gray-600 dark:text-gray-300 mb-2`">
              ✨ <strong>shadcn/ui</strong> componentes incluidos
            </p>
            <p className=`"text-sm text-gray-600 dark:text-gray-300`">
              📚 <strong>Storybook</strong> configurado (ejecuta: <code className=`"bg-gray-200 dark:bg-gray-600 px-2 py-1 rounded`">pnpm storybook</code>)
            </p>
          </div>
          
          <p className=`"text-sm text-gray-500 dark:text-gray-400 text-center`">
            Edita <code className=`"bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded`">src/App.tsx</code> para ver los cambios
          </p>
        </div>
      </div>
    </div>
  )
}

export default App
"@

$appTsx | Out-File -FilePath "src\App.tsx" -Encoding UTF8

$appCss = @"
#root {
  width: 100%;
  margin: 0;
  padding: 0;
}
"@

$appCss | Out-File -FilePath "src\App.css" -Encoding UTF8

Write-Host "${Green}✓ App de ejemplo creada${NC}"
Write-Host ""

# ==========================================
# 7. CREAR README COMPLETO
# ==========================================
Write-Host "${Blue}→ 📝 Generando README...${NC}"

$readme = @'
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

Usa el script `dev.ps1` creado en la raíz:

```powershell
.\dev.ps1
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
```

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
'@

$readme | Out-File -FilePath "README.md" -Encoding UTF8

Write-Host "${Green}✓ README generado${NC}"
Write-Host ""

# ==========================================
# 8. AGREGAR SCRIPTS ÚTILES
# ==========================================
Write-Host "${Blue}→ ⚙️  Configurando scripts adicionales...${NC}"
$null = & pnpm pkg set "scripts.format=prettier --write \`"src/**/*.{ts,tsx,json,css,md}\`"" 2>&1

Write-Host "${Green}✓ Scripts configurados${NC}"
Write-Host ""

# ==========================================
# 9. CREAR SCRIPT DEV.PS1 EN LA RAÍZ
# ==========================================
Write-Host "${Blue}→ 🚀 Creando script dev.ps1 en la raíz del proyecto...${NC}"

Set-Location ..

$devPs1 = @'
# Script de desarrollo para proyecto frontend
# Inicia el servidor de desarrollo con Vite

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$NC = "`e[0m"

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║   Frontend Development Server 🚀                          ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "frontend")) {
    Write-Host "${Red}✗ No se encuentra el directorio 'frontend'${NC}"
    Write-Host "${Yellow}  Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
}

Set-Location frontend

# Verificar que pnpm esté instalado
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "${Red}✗ pnpm no está instalado${NC}"
    Write-Host "${Yellow}  Instálalo con: npm install -g pnpm${NC}"
    exit 1
}

Write-Host "${Green}✓ Directorio frontend encontrado${NC}"
Write-Host "${Green}✓ pnpm instalado${NC}"
Write-Host ""

# Verificar dependencias
if (-not (Test-Path "node_modules")) {
    Write-Host "${Blue}→ Instalando dependencias...${NC}"
    & pnpm install
    Write-Host ""
}

Write-Host "${Blue}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Blue}  Iniciando servidor de desarrollo...${NC}"
Write-Host "${Blue}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Green}🔥 Hot-Reload activado${NC}"
Write-Host "${Green}📦 Stack: React + Vite + TypeScript + Tailwind + shadcn/ui${NC}"
Write-Host ""
Write-Host "${Yellow}→ URL: http://localhost:5173${NC}"
Write-Host ""
Write-Host "${Purple}Presiona Ctrl+C para detener${NC}"
Write-Host ""

# Iniciar Vite
& pnpm dev
'@

$devPs1 | Out-File -FilePath "dev.ps1" -Encoding UTF8

Write-Host "${Green}✓ Script dev.ps1 creado en la raíz del proyecto${NC}"
Write-Host ""

# ==========================================
# FINALIZACIÓN
# ==========================================

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✅ ¡Proyecto frontend completo creado exitosamente!${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""

Write-Host "${Blue}📁 Ubicación: .\$PROJECT_NAME${NC}"
Write-Host ""

Write-Host "${Cyan}${Bold}Stack instalado:${NC}"
Write-Host "  ${Green}✓${NC} React 18 + TypeScript"
Write-Host "  ${Green}✓${NC} Vite (build tool)"
Write-Host "  ${Green}✓${NC} Tailwind CSS"
Write-Host "  ${Green}✓${NC} shadcn/ui (componentes)"
Write-Host "  ${Green}✓${NC} Storybook (documentación)"
Write-Host ""

Write-Host "${Cyan}${Bold}Próximos pasos:${NC}"
Write-Host "  ${Green}1.${NC} .\dev.ps1           ${Gray}# Iniciar servidor de desarrollo${NC}"
Write-Host "  ${Green}2.${NC} cd $PROJECT_NAME; pnpm storybook  ${Gray}# Ver componentes${NC}"
Write-Host ""
Write-Host "${Cyan}${Bold}Comandos alternativos:${NC}"
Write-Host "  ${Green}→${NC} cd $PROJECT_NAME; pnpm dev      ${Gray}# Desarrollo manual${NC}"
Write-Host "  ${Green}→${NC} cd $PROJECT_NAME; pnpm build    ${Gray}# Build producción${NC}"
Write-Host ""

Write-Host "${Cyan}${Bold}Agregar componentes de shadcn/ui:${NC}"
Write-Host "  ${Green}→${NC} pnpx shadcn@latest add button"
Write-Host "  ${Green}→${NC} pnpx shadcn@latest add card"
Write-Host "  ${Green}→${NC} pnpx shadcn@latest add dialog"
Write-Host ""

Write-Host "${Green}🎉 ¡Todo listo para desarrollar!${NC}"
Write-Host ""
