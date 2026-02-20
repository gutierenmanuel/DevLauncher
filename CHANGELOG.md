# CHANGELOG

Historial de cambios por versión del proyecto DevScripts.

---

## v0.4.6 — 2026-02-20

### 🔧 Mejoras
- **Uninstaller limpia PATH del registro**: `uninstaller.exe` ahora elimina `DEVSCRIPTS_ROOT` de las variables de entorno del usuario y limpia todas las entradas `*devscripts*` del PATH permanente en el registro de Windows.
- **Uninstaller limpia múltiples perfiles**: Ahora elimina el bloque DevScripts de ambos perfiles PowerShell (PS5 en `WindowsPowerShell/` y PS7 en `PowerShell/`) automáticamente.
- **Script de desinstalación actualizado**: `desinstalar_devlauncher.ps1` ahora ejecuta `uninstaller.exe` directamente en la terminal actual sin abrir ventanas extras.

### ✨ Nuevo en Launcher
- **Exit code siempre visible**: Los resultados de ejecución ahora muestran el código de salida explícitamente: `(exit code: 0)` para éxito o `(exit code: 1, 2, ...)` para errores.
- **Captura completa de output**: El launcher ahora captura y muestra tanto `stdout` como `stderr` completos de los scripts ejecutados.
- **Output scrolleable**: 
  - Usa la **rueda del ratón** o las **flechas ↑↓/j/k** para desplazarte por la salida del script.
  - Indicador de posición: `[Líneas 1-20 de 150]` cuando hay más contenido.
- **Text wrapping inteligente**: Las líneas largas se ajustan automáticamente al ancho de la terminal para evitar que el texto se corte por la derecha.
- **Selección de texto habilitada**: Ahora puedes seleccionar y copiar texto del output usando **Shift + arrastre del ratón**.

---

## v0.4.5 — 2026-02-19

### ✨ Nuevo
- **Installer ejecutable Go** (`installer.exe` / `installer-linux`): instalador self-contained con TUI BubbleTea que embebe todos los scripts, launcher y assets en un único binario. Sin dependencias externas.
- **Uninstaller ejecutable Go** (`uninstaller.exe` / `uninstaller-linux`): desinstalador con TUI que elimina `~/.devlauncher/` y limpia el perfil de shell.
- **Detección de versión e instalación previa**: el installer detecta automáticamente si ya existe una versión instalada y propone actualizar o reinstalar.
- **`installer-go/build-installer.ps1` / `installer-go/build-installer.sh`**: scripts de build todo-en-uno que compilan launcher + installer + uninstaller para Windows y Linux y publican binarios en `outputs/`.
- **`CHANGELOG.md`**: este archivo, historial de cambios por versión.

### 🔧 Mejoras
- `installer-go/` estructura con módulo Go independiente, compartiendo código entre installer y uninstaller via paquetes `installer/` y `tui/`.
- Cross-compilation nativa: todo se compila desde Windows hacia Linux (y viceversa) sin toolchains adicionales.

---

## v0.4.1 → v0.4.5 — Resumen de pequeños cambios

### 🔹 Build y artefactos
- Nombres de binarios versionados en `outputs/` con formato `X.Y.Z-devlauncher*`.
- `build-all.ps1` restaura el directorio inicial al terminar (no te mueve de carpeta).
- El pipeline dejó de publicar uninstallers como artefactos finales.

### 🔹 Installer / Uninstaller
- Reducción fuerte de tamaño del installer: ahora cada installer incluye solo assets de su plataforma.
- El uninstaller dejó de ser binario embebido grande y pasó a generarse como script ligero durante la instalación (`uninstaller.ps1` / `uninstaller.sh`).
- Pantalla final del installer: ahora pide `Enter para continuar` y luego lanza automáticamente el launcher.
- Fix de auto-lanzamiento tras instalar (compatibilidad con modelo BubbleTea por valor o puntero).

### 🔹 Launcher UX
- Descubrimiento jerárquico real: subcarpetas se abren al entrar, no se aplana todo de golpe.
- Metadatos de carpeta desde README:
	- icono = emoji del header,
	- descripción = primera línea no vacía debajo del header.
- Vista principal y subcarpetas con estilo visual consistente de directorio.
- Conteos visibles por carpeta y subcarpeta (`dirs`/`scripts`) con estilo discreto.
- Versión `vX.X.X` integrada en el header ASCII (lado derecho, color del gradiente rojo).

### 🔹 Terminal `:` integrada
- Comandos `cd`, `pwd`, `ls` para navegar y operar sobre directorio de trabajo runtime.
- Los scripts se ejecutan en el directorio actual del launcher (no en ruta fija de instalación).
- Scroll con rueda del ratón en salida larga (`ls`).
- Autocompletado con `Tab` para comandos y rutas.

### 🔹 Estructura y documentación
- Nuevo bloque `configuracion_devlauncher` en `scripts/win` y `scripts/linux`.
- `tests/` movidos bajo `configuracion_devlauncher/tests`.
- READMEs añadidos/normalizados con icono en header para detección automática por el launcher.

---

## v0.3.0

### ✨ Nuevo
- **Launcher TUI Go** (`launcher-go/`): lanzador interactivo con menú jerárquico usando BubbleTea + Bubbles + Lipgloss.
- Soporte para categorías de scripts con iconos y descripciones.
- Navegación con teclado: flechas, j/k, números 1-9, Esc.
- Modo comando (`:`) desde el launcher.
- Build scripts para todas las plataformas (`build.ps1 -All`).

---

## v0.2.0

### ✨ Nuevo
- Soporte para reinstalación (detecta instalación previa y ofrece reemplazar).
- Detección automática de shell (bash/zsh).

---

## v0.1.0

### ✨ Nuevo
- Estructura inicial del proyecto: `scripts/win/`, `scripts/linux/`, `scripts/lib/`.
- Scripts organizados por categorías: build, dev, instaladores, tests, utils.
- Assets ASCII art en `static/`.
