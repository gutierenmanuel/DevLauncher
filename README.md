# 🚀 DevLauncher

Sistema avanzado de gestión y lanzamiento de scripts de desarrollo con:
- 🎯 Navegación jerárquica por categorías
- 🔧 Manejo inteligente de errores con soluciones
- 📝 Logging automático de operaciones
- 🌐 Acceso global desde cualquier directorio

## 📁 Estructura del Proyecto

```
DevLauncher/
├── installer-go/            # 📦 Código fuente del instalador ejecutable
├── launcher-go/             # 🎯 Código fuente del launcher TUI
├── outputs/                 # 📦 Binarios generados por build
│   ├── launcher-linux       # 🐧 Binario launcher Linux
│   ├── launcher.exe         # 🪟 Binario launcher Windows
│   └── launcher-mac         # 🍎 Binario launcher macOS
├── scripts/
│   ├── lib/
│   │   ├── common.sh       # 📚 Librería común de funciones
│   │   └── example_usage.sh
│   ├── linux/
│   │   ├── build/          # 🏗️ Scripts de compilación
│   │   ├── dev/            # 💻 Scripts de desarrollo
│   │   ├── inicializar_repos/  # 🆕 Inicializadores de proyectos
│   │   └── instaladores/   # 📦 Instaladores de herramientas
│   └── win/                # 🪟 Scripts para Windows
└── tests/                  # 🧪 Tests
```

## ✨ Características Principales

### 🎯 Navegación Jerárquica (¡NUEVO!)

```
📁 Categorías
   ├─ 🏗️  build (1 script)
   │   └─ 📄 Scripts
   │       └─ build.sh → ▶️ Ejecutar
   │
   ├─ 💻 dev (2 scripts)
   │   └─ 📄 Scripts
   │       ├─ dev.sh → ▶️ Ejecutar
   │       └─ copy-to-windows.sh → ▶️ Ejecutar
   │
   ├─ 🆕 inicializar_repos (3 scripts)
   │   └─ 📄 Scripts
   │       ├─ init_frontend_project.sh → ▶️ Ejecutar
   │       ├─ init_go_project.sh → ▶️ Ejecutar
   │       └─ init_wails_project.sh → ▶️ Ejecutar
   │
   └─ 📦 instaladores (4 scripts)
       └─ 📄 Scripts
           ├─ instalar_go.sh → ▶️ Ejecutar
           ├─ instalar_nodejs.sh → ▶️ Ejecutar
           ├─ instalar_pnpm.sh → ▶️ Ejecutar
           └─ instalar_wails.sh → ▶️ Ejecutar
```

**Flujo:** Selecciona categoría → Selecciona script → Ejecuta → Vuelve al menú

### 🏷️ Icono por carpeta (README)

El launcher obtiene el icono de cada carpeta leyendo su `README.md` local.

Regla recomendada:

- La primera línea útil del README debe empezar por emoji/icono.
- Formato sugerido: `# 🧪 Nombre de la carpeta`.

Ejemplos válidos:

```md
# 🛠️ Utilidades (Windows)
# 📦 Instaladores (Linux)
```

Si no encuentra icono en el README, el launcher usa uno por defecto.

### 🔧 Manejo Avanzado de Errores

Cuando algo falla, obtienes información completa:

```
╔════════════════════════════════════════════════════════════╗
║                    ✗ ERROR DETECTADO                      ║
╚════════════════════════════════════════════════════════════╝

Error: Go no está instalado
Código: GO_NOT_FOUND

🔧 Solución sugerida:
   Instala Go desde https://go.dev/dl/ o ejecuta:
   ./scripts/linux/instaladores/instalar_go.sh

ℹ Información adicional:
   • Script: dev.sh
   • Línea: 15
   • Función: main
   • Directorio: /ruta/proyecto
   • Usuario: lucas
   • Log: /tmp/script-errors-20260218.log
```

### 📝 Códigos de Error con Soluciones

| Código | Descripción | Solución Automática |
|--------|-------------|---------------------|
| `GO_NOT_FOUND` | Go no instalado | Enlace de descarga + script instalador |
| `WAILS_NOT_FOUND` | Wails no instalado | Comando de instalación |
| `PNPM_NOT_FOUND` | pnpm no instalado | Script instalador |
| `NODE_NOT_FOUND` | Node.js no instalado | Enlace + script instalador |
| `BUILD_FAILED` | Build falló | Checklist de verificación |
| `DIRECTORY_NOT_FOUND` | Directorio inexistente | Verificar ubicación |
| `PERMISSION_DENIED` | Sin permisos | Comandos chmod/chown |
| `PORT_IN_USE` | Puerto ocupado | Comando para liberar |

## 🚀 Instalación Rápida

### 1. Instalación Global con ejecutable (Recomendado)

```bash
cd /home/lucas/DataProyects/Scripts_dev
./outputs/installer-linux
source ~/.bashrc  # o ~/.zshrc si usas zsh

# Windows (PowerShell)
.\outputs\installer.exe
. $PROFILE
```

### 2. Uso Directo (Sin instalar)

```bash
cd /home/lucas/DataProyects/Scripts_dev
./outputs/launcher-linux
```

## 📖 Guía de Uso

### 🎯 Lanzador Interactivo con Navegación Jerárquica

```bash
# Con alias (después de instalar)
devlauncher
# o simplemente
dl
```

**Navegación:**
1. Ve las categorías disponibles con contador de scripts
2. Selecciona una categoría (🏗️ build, 💻 dev, etc.)
3. Ve los scripts en esa categoría
4. Selecciona un script para ejecutar
5. Después de ejecutar, puedes volver o salir

**Con fzf (si está instalado):**
- `↑/↓` - Navegar
- `Enter` - Seleccionar
- `Esc` - Volver/Salir

**Sin fzf (menú select):**
- Número + Enter - Seleccionar
- `b` - Volver a categorías
- `0` - Salir

### 📋 Listar Todos los Scripts

```bash
devlauncher --list
```

Muestra estructura completa organizada por categorías con descripciones.

### ⚡ Ejecutar Directamente

```bash
# Usando función devscript (después de instalar)
devscript dev.sh
devscript build.sh

# Usando alias directos
dev-start        # Iniciar desarrollo
dev-build        # Compilar proyecto
dev-init-frontend # Crear proyecto frontend
dev-init-go      # Crear proyecto Go
dev-init-wails   # Crear proyecto Wails
```

## 🛠️ Scripts Disponibles por Categoría

### 🏗️ Build (Compilación)
- **build.sh** - Sistema de compilación completo para Wails
  - Compila frontend (React + Vite)
  - Genera builds para Windows (debug y producción)
  - Validaciones y verificaciones automáticas

### 💻 Dev (Desarrollo)
- **dev.sh** - Servidor de desarrollo con hot-reload
  - Wails dev server
  - Recarga automática frontend y backend
  - Validación de dependencias
  
- **copy-to-windows.sh** - Copiar ejecutables a Windows

### 🆕 Inicializar Repos (Proyectos Nuevos)
- **init_frontend_project.sh** - Proyecto React completo
  - React + Vite + Tailwind CSS + pnpm
  - Configuración predeterminada
  - Estructura optimizada
  
- **init_go_project.sh** - Proyecto Go estándar
  
- **init_wails_project.sh** - Aplicación Wails completa

### 📦 Instaladores (Herramientas)
- **instalar_go.sh** - Instalar Go
- **instalar_nodejs.sh** - Instalar Node.js con nvm
- **instalar_pnpm.sh** - Instalar pnpm
- **instalar_wails.sh** - Instalar Wails CLI

## 🔧 Librería Común (common.sh)

### Funciones de Logging

```bash
success "Operación exitosa"     # ✓ Verde
info "Información importante"   # ℹ Azul
warning "Advertencia"            # ⚠ Amarillo
error "Error encontrado"         # ✗ Rojo
progress "Procesando..."         # → Cyan
debug "Debug info"               # Solo si DEBUG_MODE=1
```

### Manejo de Errores

```bash
# Verificar comandos
check_command "go" "GO_NOT_FOUND" "Go no está instalado"

# Verificar múltiples comandos
check_commands "go" "git" "npm"

# Verificar directorios
check_directory "/ruta/dir" "El directorio no existe"

# Verificar archivos
check_file "/ruta/archivo" "El archivo no existe"

# Ejecutar con manejo de errores
safe_run "npm install" "NPM_FAILED" "Falló npm install"

# Manejar errores personalizados
handle_error "MI_ERROR" "Descripción" "Solución sugerida"
```

### Utilidades

```bash
# Mostrar header bonito
show_header "Mi Script" "Subtítulo opcional"

# Mostrar versión de comando
show_version "node" "--version"

# Confirmar con usuario
if confirm "¿Continuar?" "y"; then
    # hacer algo
fi

# Activar trap de errores
setup_error_trap  # Captura errores con línea exacta
```

## 📝 Crear Nuevos Scripts

### 1. Plantilla Básica

```bash
#!/bin/bash
# Descripción breve del script (aparecerá en el launcher)

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")/lib/common.sh"

# Configurar manejo de errores
set -e
trap 'error "El script falló en la línea $LINENO"' ERR

# Header
show_header "Mi Nuevo Script" "Descripción opcional"

# Verificar dependencias
check_command "git" "GIT_NOT_FOUND" || exit 1

# Tu código aquí
progress "Haciendo algo..."
success "¡Completado!"
```

### 2. Ubicación

Coloca tu script en la carpeta apropiada según su categoría:

```
scripts/linux/
├── build/          # Scripts de compilación
├── dev/            # Scripts de desarrollo
├── instaladores/   # Scripts de instalación
└── inicializar_repos/  # Scripts de inicialización
```

### 3. Permisos

```bash
chmod +x tu-script.sh
```

**¡El launcher lo detectará automáticamente!** 🎉

## 🐛 Debugging y Logs

### Activar Modo Debug

```bash
DEBUG_MODE=1 devscript tu-script.sh
```

Mostrará mensajes adicionales de debug y el flujo de ejecución.

### Ver Logs

```bash
# Ver el log del día actual
cat /tmp/script-errors-$(date +%Y%m%d).log

# Seguir el log en tiempo real
tail -f /tmp/script-errors-$(date +%Y%m%d).log

# Buscar errores específicos
grep "ERROR" /tmp/script-errors-*.log
```

### Estructura del Log

```
[2026-02-18 14:30:15] [INFO] Iniciando script dev.sh
[2026-02-18 14:30:16] [SUCCESS] Go detectado: 1.21.0
[2026-02-18 14:30:17] [ERROR] Code: WAILS_NOT_FOUND | Description: Wails no instalado | Script: dev.sh | Line: 25
```

## �� Ejemplos de Uso

### Ejemplo 1: Flujo Completo de Desarrollo

```bash
# 1. Instalar herramientas necesarias
devlauncher
# → Selecciona 📦 instaladores
# → Selecciona instalar_go.sh
# → Ejecuta

# 2. Crear proyecto nuevo
devlauncher
# → Selecciona 🆕 inicializar_repos
# → Selecciona init_frontend_project.sh
# → Ejecuta

# 3. Iniciar desarrollo
cd mi-proyecto
dev-start  # o devlauncher → 💻 dev → dev.sh
```

### Ejemplo 2: Build y Deploy

```bash
# Compilar proyecto
dev-build  # o devlauncher → 🏗️ build → build.sh

# Copiar a Windows
devscript copy-to-windows.sh
```

### Ejemplo 3: Manejo de Errores

```bash
# Si un script falla, verás:
devlauncher → 💻 dev → dev.sh

# Output si Go no está instalado:
╔════════════════════════════════════════════════════════════╗
║                    ✗ ERROR DETECTADO                      ║
╚════════════════════════════════════════════════════════════╝

Error: Go no está instalado
Código: GO_NOT_FOUND

🔧 Solución sugerida:
   Instala Go desde https://go.dev/dl/ o ejecuta:
   ./scripts/linux/instaladores/instalar_go.sh

# Puedes entonces ejecutar directamente:
devlauncher → 📦 instaladores → instalar_go.sh
```

## 🤝 Contribuir

### Agregar un nuevo script:

1. **Crea el script** en la carpeta apropiada
2. **Agrega descripción** en las primeras líneas con formato:
   ```bash
   # Script para hacer X
   ```
3. **Usa la librería común** para logging y errores
4. **Hazlo ejecutable**: `chmod +x tu-script.sh`

### Agregar un nuevo código de error:

Edita `scripts/lib/common.sh` y agrega en `get_error_solution()`:

```bash
"MI_NUEVO_ERROR")
    echo "Descripción del problema"
    echo "   ${GREEN}Solución paso 1${NC}"
    echo "   ${GREEN}Solución paso 2${NC}"
    ;;
```

## 🎓 Consejos y Trucos

### 1. Instalar fzf para mejor experiencia

```bash
# Ubuntu/Debian
sudo apt install fzf

# Con el launcher tendrás un menú mucho más bonito
```

### 2. Alias personalizados

Después de instalar, puedes agregar más alias en tu `~/.bashrc`:

```bash
alias dl-dev="devscript dev.sh"
alias dl-build="devscript build.sh"
alias dl-frontend="devscript init_frontend_project.sh"
```

### 3. Variables de entorno

```bash
# Activar debug permanentemente
echo 'export DEBUG_MODE=1' >> ~/.bashrc

# Cambiar ubicación de logs
echo 'export ERROR_LOG_FILE=~/dev-scripts.log' >> ~/.bashrc
```

## 📄 Licencia

MIT License - Siéntete libre de usar y modificar

## 👤 Autor

**Lucas** - DevLauncher Project

---

## 🆘 Ayuda y Soporte

### Comandos de ayuda
```bash
devlauncher --help     # Ver opciones del launcher
devlauncher --list     # Listar todos los scripts
```

### Problemas comunes

**El launcher no funciona:**
```bash
chmod +x outputs/launcher-linux
./outputs/launcher-linux
```

**Los scripts no se encuentran:**
```bash
# Reinstalar
./outputs/installer-linux
source ~/.bashrc
```

**Errores de permisos:**
```bash
chmod +x scripts/**/*.sh
```

### Logs para debugging
```bash
tail -f /tmp/script-errors-$(date +%Y%m%d).log
```

---

**¿Más preguntas?** Revisa los logs en `/tmp/script-errors-*.log` o consulta el código fuente de `common.sh` para ver todas las funciones disponibles.

🎉 **¡Disfruta de tu sistema de scripts mejorado!**
