# CHANGELOG

Historial de cambios por versión del proyecto DevScripts.

---

## v0.4.0 — 2026-02-19

### ✨ Nuevo
- **Installer ejecutable Go** (`installer.exe` / `installer-linux`): instalador self-contained con TUI BubbleTea que embebe todos los scripts, launcher y assets en un único binario. Sin dependencias externas.
- **Uninstaller ejecutable Go** (`uninstaller.exe` / `uninstaller-linux`): desinstalador con TUI que elimina `~/.devscripts/` y limpia el perfil de shell.
- **Detección de versión e instalación previa**: el installer detecta automáticamente si ya existe una versión instalada y propone actualizar o reinstalar.
- **`installer-go/build-installer.ps1` / `installer-go/build-installer.sh`**: scripts de build todo-en-uno que compilan launcher + installer + uninstaller para Windows y Linux y publican binarios en `outputs/`.
- **`CHANGELOG.md`**: este archivo, historial de cambios por versión.

### 🔧 Mejoras
- `installer-go/` estructura con módulo Go independiente, compartiendo código entre installer y uninstaller via paquetes `installer/` y `tui/`.
- Cross-compilation nativa: todo se compila desde Windows hacia Linux (y viceversa) sin toolchains adicionales.

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
