# 🚀 Scripts Development Launcher

Sistema de gestión y lanzamiento de scripts de desarrollo con manejo avanzado de errores y acceso global.

## 📁 Estructura del Proyecto

```
Scripts_dev/
├── launcher.sh              # Lanzador universal interactivo
├── install.sh               # Instalador para acceso global
├── scripts/
│   ├── lib/
│   │   ├── common.sh       # Librería común de funciones
│   │   └── example_usage.sh
│   ├── linux/
│   │   ├── build/          # Scripts de compilación
│   │   ├── dev/            # Scripts de desarrollo
│   │   ├── inicializar_repos/  # Inicializadores de proyectos
│   │   └── instaladores/   # Instaladores de herramientas
│   └── win/                # Scripts para Windows
└── tests/                  # Tests (si aplica)
```

## ✨ Características

- 🎯 **Lanzador interactivo** con interfaz de menú (fzf o select)
- 🔧 **Manejo avanzado de errores** con soluciones sugeridas
- 📝 **Logging automático** de todas las operaciones
- 🌐 **Acceso global** desde cualquier directorio
- 🎨 **Interfaz colorida** y fácil de usar
- 📦 **Organización por categorías** (build, dev, instaladores, etc.)

## 🚀 Instalación Rápida

### 1. Instalación Global (Recomendado)

```bash
cd /home/lucas/DataProyects/Scripts_dev
./install.sh
source ~/.bashrc  # o ~/.zshrc si usas zsh
```

Esto te permitirá usar los scripts desde cualquier ubicación.

### 2. Uso Directo

```bash
cd /home/lucas/DataProyects/Scripts_dev
./launcher.sh
```

## 📖 Uso

### Lanzador Interactivo

```bash
# Con alias (después de instalar)
devlauncher
# o simplemente
dl

# Sin instalar
./launcher.sh
```

### Listar Scripts Disponibles

```bash
devlauncher --list
# o
./launcher.sh --list
```

### Ejecutar Script Específico

```bash
# Usando la función devscript (después de instalar)
devscript dev.sh

# Usando alias directos
dev-start        # Iniciar desarrollo
dev-build        # Compilar proyecto
dev-init-frontend # Crear proyecto frontend
dev-init-go      # Crear proyecto Go
dev-init-wails   # Crear proyecto Wails
```

## 🛠️ Scripts Disponibles

### 🏗️ Build
- **build.sh** - Sistema de compilación completo

### 💻 Development
- **dev.sh** - Servidor de desarrollo con hot-reload
- **copy-to-windows.sh** - Copiar ejecutables a Windows

### 🆕 Inicializadores de Proyectos
- **init_frontend_project.sh** - React + Vite + Tailwind + pnpm
- **init_go_project.sh** - Proyecto Go estándar
- **init_wails_project.sh** - Aplicación Wails completa

### 📦 Instaladores
- **instalar_go.sh** - Instalar Go
- **instalar_nodejs.sh** - Instalar Node.js con nvm
- **instalar_pnpm.sh** - Instalar pnpm
- **instalar_wails.sh** - Instalar Wails CLI

## 🔧 Librería Común (common.sh)

La librería proporciona funciones útiles para todos los scripts:

### Funciones de Logging
```bash
success "Operación exitosa"     # Mensaje verde con ✓
info "Información importante"   # Mensaje azul con ℹ
warning "Advertencia"            # Mensaje amarillo con ⚠
error "Error encontrado"         # Mensaje rojo con ✗
progress "Procesando..."         # Mensaje cyan con →
```

### Manejo de Errores
```bash
# Verificar comandos
check_command "go" "GO_NOT_FOUND" "Go no está instalado"

# Verificar directorios
check_directory "/ruta/dir" "El directorio no existe"

# Ejecutar con manejo de errores
safe_run "npm install" "NPM_FAILED" "Falló la instalación de npm"

# Manejar errores personalizados
handle_error "MI_ERROR" "Descripción del error" "Solución sugerida"
```

### Utilidades
```bash
# Mostrar header
show_header "Mi Script" "Subtítulo opcional"

# Confirmar acción
if confirm "¿Continuar con la operación?"; then
    # hacer algo
fi

# Mostrar versión
show_version "node" "--version"
```

## 📝 Crear Nuevos Scripts

### 1. Estructura Básica

```bash
#!/bin/bash
# Descripción breve del script

# Cargar librería común
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/lib/common.sh"

# Tu código aquí
show_header "Mi Nuevo Script"

# Verificar dependencias
check_command "git" "GIT_NOT_FOUND" || exit 1

# Resto del script...
```

### 2. Ubicación

Coloca tu script en la carpeta apropiada:
- `scripts/linux/build/` - Scripts de compilación
- `scripts/linux/dev/` - Scripts de desarrollo
- `scripts/linux/instaladores/` - Scripts de instalación
- `scripts/linux/inicializar_repos/` - Scripts de inicialización

### 3. Permisos

```bash
chmod +x tu-script.sh
```

El lanzador detectará automáticamente el nuevo script.

## 🐛 Debugging

### Activar Modo Debug

```bash
DEBUG_MODE=1 devscript tu-script.sh
```

### Ver Logs

```bash
# Ver el log del día
cat /tmp/script-errors-$(date +%Y%m%d).log

# Seguir el log en tiempo real
tail -f /tmp/script-errors-$(date +%Y%m%d).log
```

## 🎨 Códigos de Error Predefinidos

La librería maneja automáticamente estos errores:

- `GO_NOT_FOUND` - Go no está instalado
- `WAILS_NOT_FOUND` - Wails no está instalado
- `PNPM_NOT_FOUND` - pnpm no está instalado
- `NODE_NOT_FOUND` - Node.js no está instalado
- `GIT_NOT_FOUND` - Git no está instalado
- `BUILD_FAILED` - Falló la compilación
- `NETWORK_ERROR` - Error de conexión
- `PORT_IN_USE` - Puerto ya en uso
- `DIRECTORY_NOT_FOUND` - Directorio no encontrado
- `PERMISSION_DENIED` - Problema de permisos

Cada error incluye soluciones sugeridas automáticamente.

## 📚 Ejemplos

### Ejemplo 1: Inicializar un proyecto frontend
```bash
dev-init-frontend mi-proyecto
# o
devscript init_frontend_project.sh mi-proyecto
```

### Ejemplo 2: Iniciar desarrollo
```bash
dev-start
# o desde cualquier directorio del proyecto
cd /ruta/a/mi/proyecto
devlauncher  # seleccionar dev.sh
```

### Ejemplo 3: Compilar proyecto
```bash
dev-build
```

## 🤝 Contribuir

Para agregar nuevos scripts:

1. Crea tu script en la carpeta apropiada
2. Incluye una descripción en las primeras líneas
3. Usa la librería común para manejo de errores
4. Hazlo ejecutable con `chmod +x`

## 📄 Licencia

[Tu licencia aquí]

## 👤 Autor

Lucas - DevLauncher Project

---

**¿Necesitas ayuda?** Ejecuta `devlauncher --help` o revisa los logs en `/tmp/script-errors-*.log`
