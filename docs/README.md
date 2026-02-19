# 🚀 DevLauncher - Go + Bubbletea Edition

**Launcher universal de scripts de desarrollo** con interfaz TUI moderna usando Go y Bubbletea.

**Versión actual**: v1.4.0

## ✨ Características

- 🎯 **Navegación con flechas** - UI moderna tipo menú interactivo
- 🏗️ **Navegación jerárquica** - Categorías → Scripts
- 📦 **Binario standalone** - Sin dependencias (bash/powershell)
- 🌐 **Cross-platform** - Un código, múltiples plataformas
- 🎨 **UI moderna** - Bubbletea TUI con Lipgloss
- ⚡ **Rápido** - Binario compilado nativo
- 🎨 **Headers aleatorios** - ASCII art con degradado dinámico
- 💻 **Terminal integrada** - Comandos interactivos con `:`
- 🔢 **Navegación rápida** - Teclas 1-9 para selección directa

## 🆕 Nuevo en v1.4.0

**Header único en inicio**
- El header ASCII solo se muestra **una vez** al entrar al programa
- No se repite al navegar entre menús
- Ahorra espacio vertical
- Mejor experiencia en terminales pequeños

## 🆕 Nuevo en Go Edition

### Mejoras sobre la versión Shell/PowerShell

| Característica | Shell/PS1 | Go + Bubbletea |
|----------------|-----------|----------------|
| **Navegación** | Números | Flechas ↑/↓ + números |
| **Dependencias** | Bash/PowerShell | Ninguna |
| **Distribución** | 2 archivos (.sh + .ps1) | 1 binario por plataforma |
| **Mantenimiento** | 2 codebases | 1 codebase |
| **Performance** | Interpretado | Compilado nativo |
| **Tamaño** | ~50KB | ~5MB |
| **Terminal** | ❌ | ✅ Comandos integrados |
| **Headers** | Estático | ✅ Aleatorios con degradado |

### Controles

```
↑/↓ o j/k    - Navegar
Enter        - Seleccionar
Esc          - Volver
q            - Salir
```

## 📦 Instalación

### Opción 1: Usar binario pre-compilado

```bash
# Linux
cd /home/lucas/DataProyects/Scripts_dev
./outputs/launcher-linux

# Windows
./outputs/launcher.exe

# macOS
./outputs/launcher-mac
```

### Opción 2: Compilar desde código

```bash
cd launcher-go
go build -o ../outputs/launcher-linux
```

### Opción 3: Cross-compile para todas las plataformas

```bash
cd launcher-go
./build.sh
# Genera: outputs/launcher-linux, outputs/launcher.exe, outputs/launcher-mac
```

## 🚀 Uso

### Modo Interactivo (TUI)

```bash
./outputs/launcher-linux
```

Navegación visual con flechas:
1. Selecciona categoría
2. Selecciona script
3. El script se ejecuta automáticamente
4. Vuelve al menú o sal

### Listar Scripts

```bash
./outputs/launcher-linux --list
```

Muestra todos los scripts organizados por categoría.

### Ayuda

```bash
./outputs/launcher-linux --help
```

## 📁 Estructura del Proyecto

```
Scripts_dev/
├── outputs/
│   ├── launcher-linux      # Binario Linux (4.7MB)
│   ├── launcher.exe        # Binario Windows (5.1MB)
│   └── launcher-mac        # Binario macOS (4.6MB)
├── launcher-go/            # Código fuente Go
│   ├── main.go            # Entry point
│   ├── models/
│   │   ├── app.go        # Bubbletea model (state machine)
│   │   ├── category.go   # Scanner de categorías
│   │   ├── script.go     # Scanner de scripts
│   │   └── executor.go   # Ejecución de scripts
│   ├── ui/
│   │   ├── styles.go     # Estilos Lipgloss
│   │   ├── views.go      # Renderizado de vistas
│   │   └── messages.go   # Mensajes Bubbletea
│   ├── utils/
│   │   ├── platform.go   # Detección de plataforma
│   │   └── icons.go      # Iconos de categorías
│   ├── build.sh          # Script de compilación
│   └── go.mod            # Dependencias
├── scripts/
│   ├── linux/            # Scripts para Linux/macOS
│   │   ├── gestion_linux/
│   │   ├── inicializar_repos/
│   │   ├── iniciar_sistema/
│   │   └── instaladores/
│   └── win/              # Scripts para Windows
└── static/
    └── asciiart.txt      # ASCII art header
```

## 🛠️ Desarrollo

### Requisitos

- Go 1.24.2+
- Dependencias (auto-instaladas con `go build`):
  - `github.com/charmbracelet/bubbletea`
  - `github.com/charmbracelet/lipgloss`
  - `github.com/charmbracelet/bubbles/list`

### Compilar

```bash
cd launcher-go
go build -o launcher
```

### Compilar para otra plataforma

```bash
# Desde Linux, compilar para Windows
GOOS=windows GOARCH=amd64 go build -o ../outputs/launcher.exe

# Desde cualquier SO, compilar para Linux
GOOS=linux GOARCH=amd64 go build -o ../outputs/launcher-linux

# macOS
GOOS=darwin GOARCH=amd64 go build -o ../outputs/launcher-mac
```

### Compilar todo de una vez

```bash
cd launcher-go
./build.sh
# Genera binarios en ../outputs para Linux, Windows y macOS
```

## 🎨 Arquitectura

### Bubbletea Pattern (Elm Architecture)

```go
Model  -> State de la aplicación
Init   -> Inicialización
Update -> Manejo de mensajes (navegación, ejecución)
View   -> Renderizado de UI
```

### Estados de la aplicación

```
CategoryView    → Muestra categorías disponibles
   ↓ (Enter)
ScriptView      → Muestra scripts de la categoría
   ↓ (Enter)
ExecutingView   → Ejecuta el script seleccionado
   ↓ (automático)
ResultView      → Muestra resultado (éxito/error)
   ↓ (Enter)
ScriptView      → Vuelve a scripts
```

### Flujo de datos

```
1. ScanCategories() -> []Category
2. Usuario selecciona categoría
3. ScanScripts(categoryPath) -> []Script
4. Usuario selecciona script
5. ExecuteScript(script) -> exitCode
6. Muestra resultado
```

## 📝 Agregar Nuevos Scripts

Los scripts se detectan automáticamente. Solo agrégalos a:

```bash
scripts/linux/tu-categoria/tu-script.sh
# o
scripts/win/tu-categoria/tu-script.ps1
```

**Agregar descripción** (primera línea de comentario):

```bash
#!/bin/bash
# Script para hacer algo útil
# <- Esta línea se muestra en el launcher
```

## 🔧 Agregar Nueva Categoría

1. Crea carpeta: `scripts/linux/nueva-categoria/`
2. Agrega icono en `utils/icons.go`:

```go
func CategoryIcon(category string) string {
    icons := map[string]string{
        "nueva-categoria": "🎯",
        // ...
    }
}
```

3. Agrega descripción:

```go
func CategoryDescription(category string) string {
    descriptions := map[string]string{
        "nueva-categoria": "Descripción de la categoría",
        // ...
    }
}
```

## 🧪 Testing

### Probar navegación

```bash
./outputs/launcher-linux
# Navega con flechas
# Presiona Enter para seleccionar
# Presiona Esc para volver
# Presiona q para salir
```

### Probar ejecución de scripts

```bash
./outputs/launcher-linux
# Navega a cualquier categoría
# Selecciona un script
# Verifica que se ejecuta correctamente
# Verifica mensaje de éxito/error
```

### Probar --list

```bash
./outputs/launcher-linux --list
# Debe mostrar todos los scripts organizados
```

## 📊 Comparación de Tamaño

```
Versión Shell:
  launcher.sh:  ~16KB
  launcher.ps1: ~15KB
  Total:        ~31KB

Versión Go:
  launcher-linux: 4.7MB
  launcher.exe:   5.1MB
  launcher-mac:   4.6MB
```

**Trade-off:** Mayor tamaño pero **zero dependencias** y mejor UX.

## 🎯 Ventajas de Go + Bubbletea

### Para Usuarios
- ✅ No necesita bash/powershell instalado
- ✅ Navegación más intuitiva (flechas vs números)
- ✅ UI más profesional
- ✅ Más rápido (binario compilado)

### Para Desarrolladores
- ✅ Un solo codebase para todas las plataformas
- ✅ Type safety (Go es tipado)
- ✅ Mejor testeable
- ✅ Más fácil de mantener

### Para Distribución
- ✅ Un solo archivo ejecutable
- ✅ Sin instalación de intérpretes
- ✅ Funciona en máquinas "limpias"

## 🐛 Debugging

### Ver qué plataforma detecta

```go
// En utils/platform.go
fmt.Println("Platform:", DetectPlatform())
```

### Ver qué scripts encuentra

```bash
./outputs/launcher-linux --list
```

### Logs de ejecución

Los scripts se ejecutan directamente con stdout/stderr visible.

## 📚 Referencias

- [Bubbletea](https://github.com/charmbracelet/bubbletea) - Framework TUI
- [Lipgloss](https://github.com/charmbracelet/lipgloss) - Estilos de terminal
- [Bubbles](https://github.com/charmbracelet/bubbles) - Componentes TUI

## 🔄 Migración desde Shell/PS1

El launcher Go **convive** con las versiones shell:

```bash
# Viejo (sigue funcionando)
./launcher.sh

# Nuevo
./outputs/launcher-linux
```

**No es necesario borrar** los launchers antiguos. Ambos funcionan.

## 🚀 Roadmap Futuro

- [ ] Búsqueda de scripts (fuzzy find)
- [ ] Historial de scripts ejecutados
- [ ] Favoritos
- [ ] Configuración (colores, etc.)
- [ ] Modo batch (ejecutar múltiples scripts)
- [ ] Output buffering (mostrar en TUI en lugar de terminal)

## 📄 Licencia

MIT License

## 👤 Autor

**Lucas** - DevLauncher Project (Go Edition)

---

## 🆘 FAQ

**P: ¿Necesito instalar Go para usar el launcher?**  
R: No, solo si quieres compilar. Los binarios son standalone.

**P: ¿Funciona en Windows?**  
R: Sí, usa `outputs/launcher.exe`

**P: ¿Por qué el binario es tan grande?**  
R: Go incluye el runtime. Pero no necesita dependencias externas.

**P: ¿Puedo usar el launcher viejo?**  
R: Sí, ambos conviven sin problemas.

**P: ¿Cómo agrego mis propios scripts?**  
R: Simplemente agrégalos a `scripts/linux/categoria/`. Se detectan automáticamente.

**P: ¿Funciona WSL?**  
R: Sí, usa `outputs/launcher-linux`

---

🎉 **¡Disfruta del nuevo launcher con Bubbletea!**
