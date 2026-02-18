# Changelog - DevLauncher

## v1.4.0 - Header Único (2026-02-18)

### 🎯 Mejora de UX

**Header ASCII solo en inicio**
- El header ASCII ahora solo se muestra **UNA VEZ** al entrar al programa
- No se muestra al navegar entre menús (categorías → scripts → resultados)
- Se vuelve a mostrar al ejecutar el programa nuevamente
- Ahorra espacio vertical en pantalla
- Mejor experiencia en terminales pequeños

### 🔧 Cambios Técnicos

- Agregado campo `headerShown bool` al struct Model
- Modificado método `View()` para controlar renderizado del header
- La bandera se activa después de la primera vista
- Cambio de receivers a punteros (Init, Update, View) para mutabilidad

### 📊 Comportamiento

```
Ejecución 1:
┌──────────────────┐
│  [ASCII ART]     │  ← Se muestra
│                  │
│  Menú Principal  │
└──────────────────┘

Navegación → Scripts:
┌──────────────────┐
│  Lista Scripts   │  ← No hay header
│  - script1.sh    │
│  - script2.sh    │
└──────────────────┘

Salir y volver:
┌──────────────────┐
│  [ASCII ART]     │  ← Se muestra de nuevo
│                  │
│  Menú Principal  │
└──────────────────┘
```

---

## v1.3.0 - Headers Dinámicos (2026-02-18)

### ✨ Nuevas Funcionalidades

**Sistema de Headers Aleatorios**
- Selección aleatoria de cualquier archivo `.txt` en `static/`
- Seed basado en timestamp (nanosegundos)
- 8 headers detectados automáticamente
- Extensible: solo agregar más `.txt`

**Sistema de Degradado de Color**
- 8 colores en gradiente automático
- Purple → Blue → Cyan → Pink
- Aplicado línea por línea
- Sin hardcoding de colores

**Mejoras de Layout**
- Espacio automático después del header
- Separación clara entre header y menú
- Layout más limpio y profesional

### 🎨 Headers Disponibles

```
static/
├── ascii_rebel.txt
├── ascii_simple_01.txt
├── blur_viusion.txt
├── cerdito.txt
├── degraded_text.txt
├── waifu.txt
├── asciiart2.txt
├── asciiart3.txt
└── asciiart4.txt
```

### 🌈 Paleta de Colores

```
1. #9b59b6 (Purple)
2. #8e44ad (Dark Purple)
3. #3498db (Blue)
4. #2980b9 (Dark Blue)
5. #1abc9c (Cyan)
6. #16a085 (Dark Cyan)
7. #e74c3c (Pink/Red)
8. #c0392b (Dark Red)
```

---

## v1.2.0 - Navegación Mejorada (2026-02-18)

### ✨ Nuevas Funcionalidades

**Navegación con Punto (.)**
- `.` = volver un nivel arriba (estilo Unix)
- Funciona en cualquier vista
- Similar a `cd ..`

**Visualización de Ruta**
- Muestra la ruta del proyecto: `📂 /ruta/al/proyecto`
- Aparece encima del breadcrumb
- Contexto visual mejorado

### 🔧 Cambios Técnicos

- Modificado `RenderBreadcrumb()` para aceptar `rootDir`
- Actualizado manejo de teclas con caso especial para `.`
- Pasado parámetro `rootDir` a todas las funciones de renderizado

---

## v1.1.0 - Terminal y Mejoras (2026-02-18)

### ✨ Nuevas Funcionalidades

**Navegación con Números**
- Teclas 1-9 para selección rápida sin Enter
- Funciona en menús de categorías y scripts
- UX más fluida

**Terminal de Comandos**
- Activar con `:` (estilo Vim)
- Comandos disponibles:
  - `:help` / `:h` - Mostrar ayuda
  - `:ls` - Listar items actuales
  - `:search <texto>` - Buscar scripts
  - `:N` - Saltar al item N
  - `:clear` - Limpiar salida
  - `:quit` / `:q` - Salir

**ASCII Art Completo**
- Ahora muestra todas las líneas (antes solo últimas 7)
- Headers más grandes y detallados
- Sin truncamiento

**Layout Compacto**
- Reducido espaciado entre elementos del menú
- Más información visible en pantalla
- Mejor uso del espacio vertical

### 🔧 Cambios Técnicos

- Nuevo archivo `models/command.go`
- Implementación de `CommandMode` con textinput
- Parseo de comandos con búsqueda fuzzy
- Componente de entrada de texto integrado

---

## v1.0.0 - Lanzamiento Inicial (2026-02-18)

### 🎉 Primera Versión Go + Bubbletea

**Funcionalidades Core**
- Migración completa de Shell/PowerShell a Go
- Framework Bubbletea (arquitectura Elm)
- Navegación jerárquica (categorías → scripts)
- Ejecución de scripts multiplataforma
- Detección automática de plataforma

**Navegación**
- Flechas ↑↓ y teclas Vim (j/k)
- Enter para seleccionar
- Esc para volver
- 0 para salir/volver (contextual)
- q para salir

**UI/UX**
- ASCII Art header coloreado
- Breadcrumb de navegación
- Estilos con Lipgloss
- Vista de categorías con iconos
- Vista de scripts con descripciones
- Vista de ejecución
- Vista de resultados con código de salida

**CLI**
- `--help` / `-h`: Mostrar ayuda
- `--list` / `-l`: Listar scripts organizados
- (sin args): Modo interactivo

**Multiplataforma**
- Binarios para Linux, Windows, macOS
- Detección automática de SO
- Soporte para .sh, .ps1, .bat
- Tamaños: ~5MB por binario
- Zero dependencias externas

**Arquitectura**
```
launcher-go/
├── main.go              # Punto de entrada
├── models/
│   ├── app.go          # Modelo Bubbletea
│   ├── category.go     # Scanner de categorías
│   ├── script.go       # Scanner de scripts
│   └── executor.go     # Motor de ejecución
├── ui/
│   ├── styles.go       # Estilos Lipgloss
│   ├── views.go        # Renderizado de vistas
│   └── messages.go     # Mensajes Bubbletea
└── utils/
    ├── platform.go     # Detección de SO
    └── icons.go        # Iconos y metadatos
```

### 📦 Binarios

- `launcher-linux`: 4.7MB (Linux/WSL)
- `launcher.exe`: 5.1MB (Windows)
- `launcher-mac`: 4.6MB (macOS)

### 🔧 Build

```bash
cd launcher-go
./build.sh  # Cross-compilation para todas las plataformas
```

---

## Línea de Tiempo

```
v1.0.0 → Migración Go + Bubbletea
v1.1.0 → Terminal + Números + ASCII completo
v1.2.0 → Navegación . + Ruta visible
v1.3.0 → Headers aleatorios + Degradado
v1.4.0 → Header único (solo al inicio)
```

## Próximas Ideas

- [ ] Headers animados por frames
- [ ] Headers por hora del día
- [ ] Headers estacionales
- [ ] Temas de color configurables
- [ ] Búsqueda en tiempo real
- [ ] Historial de comandos
- [ ] Favoritos/marcadores
- [ ] Configuración persistente

---

**Proyecto**: DevLauncher  
**Lenguaje**: Go 1.24+  
**Framework**: Bubbletea + Lipgloss  
**Licencia**: MIT  
