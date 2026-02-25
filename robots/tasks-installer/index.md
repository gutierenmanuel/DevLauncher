````markdown
# Plan de Refactorización – installer-go

## Objetivo

Reestructurar `installer-go/` de dos paquetes monolíticos (`installer/`, `tui/`) a tres capas limpias:
- `core/`       → funciones puras (sin I/O, sin efectos secundarios)
- `middleware/`  → funciones impuras (filesystem, procesos, configuración del SO)
- `app/`        → orquestación BubbleTea (Model, Init, Update, View para installer y uninstaller)

## Estructura actual

```
installer-go/
  installer/
    core.go             → mezcla de funciones puras e impuras
    shell_unix.go       → I/O shell config (Unix)
    shell_windows.go    → I/O shell config (Windows)
    shortcut_unix.go    → creación de acceso directo (Unix)
    shortcut_windows.go → creación de acceso directo (Windows)
    uninstaller_unix.go → generación script uninstaller (Unix)
    uninstaller_windows.go
  tui/
    model.go            → BubbleTea model del installer (~500 líneas)
    uninstaller.go      → BubbleTea model del uninstaller (~317 líneas)
    styles.go           → estilos lipgloss
  main.go               → entry point installer
  cmd/uninstaller/
    main.go             → entry point uninstaller
  embed.go              → embed.FS
```

## Estrategia

**Incremental**: el repo compila correctamente después de cada tarea.  
Cada tarea crea el nuevo código → redirige los imports → elimina el código viejo.

## Tareas en orden

| # | Archivo | Estado | Descripción |
|---|---------|--------|-------------|
| 01 | [task_01_structure.md](task_01_structure.md) | ✅ completado | Crear carpetas `core/`, `middleware/`, `app/` con stubs |
| 02 | [task_02_core.md](task_02_core.md)           | ✅ completado | Migrar funciones puras a `core/` |
| 03 | [task_03_middleware.md](task_03_middleware.md)| ✅ completado | Migrar funciones de I/O a `middleware/` |
| 04 | [task_04_app.md](task_04_app.md)             | ✅ completado | Migrar TUI (installer + uninstaller) a `app/` |
| 05 | [task_05_cleanup.md](task_05_cleanup.md)     | ✅ completado | Eliminar `installer/` y `tui/` legacy |
| 06 | [task_06_main.md](task_06_main.md)           | ✅ completado | Actualizar `main.go` y `cmd/uninstaller/main.go` |
| 07 | [task_07_validation.md](task_07_validation.md)| ✅ completado | Build final + checks de capas + test funcional |

## Mapa de responsabilidades final

```
core/
  version.go     → ParseVersion, CompareVersions, parseParts (semver puro)
  assets.go      → CountAssets, mapAssetPath, isExecutable (lógica embed pura)
  paths.go       → GetInstallDir, GetLauncherPath (resolución de rutas determinista)
  types.go       → ExistingInstall struct + Phase + UninstallPhase (tipos de datos)

middleware/
  detection.go        → DetectExistingInstall (lee filesystem)
  extractor.go        → ExtractAssets (escribe filesystem)
  shell_unix.go       → ConfigureShell, RemoveShellConfig, buildUnixBlock (Unix)
  shell_windows.go    → ConfigureShell, RemoveShellConfig, buildWindowsBlock (Windows)
  shortcut_unix.go    → CreateDesktopShortcut (Unix)
  shortcut_windows.go → CreateDesktopShortcut (Windows)
  uninstaller_unix.go    → GenerateUninstaller (Unix)
  uninstaller_windows.go → GenerateUninstaller (Windows)

app/
  styles.go           → estilos lipgloss (desde tui/styles.go)
  messages.go         → tipos Tea msg + cmd factories para installer y uninstaller
  model.go            → InstallerModel struct, NewModel, Init, Update (installer)
  views.go            → funciones de render del installer
  uninstaller.go      → UninstallModel struct, NewUninstallModel, Init, Update
  uninstaller_views.go→ funciones de render del uninstaller

main.go               → importa solo app/
cmd/uninstaller/
  main.go             → importa solo app/
```

## Estado de los estados

- ⬜ pendiente
- 🔄 en progreso
- ✅ completado
- ❌ bloqueado
````
