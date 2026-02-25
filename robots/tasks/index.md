# Plan de Refactorización – launcher-go

## Objetivo

Reestructurar `launcher-go/` de un monolito en `models/` a tres capas limpias:
- `core/`       → funciones puras (sin I/O, sin efectos secundarios)
- `middleware/`  → funciones impuras (filesystem, ejecución de procesos, OS)
- `app/`        → orquestación BubbleTea (Model, Init, Update, View)

## Estrategia

**Incremental**: el repo compila correctamente después de cada tarea.  
Cada tarea crea el nuevo código → redirige los imports → elimina el código viejo.

## Tareas en orden

| # | Archivo | Estado | Descripción |
|---|---------|--------|-------------|
| 01 | [task_01_structure.md](task_01_structure.md) | ✅ completado | Crear carpetas `core/`, `middleware/`, `app/` con archivos vacíos (stubs) |
| 02 | [task_02_core.md](task_02_core.md)           | ✅ completado | Migrar tipos puros y funciones sin I/O a `core/` |
| 03 | [task_03_middleware.md](task_03_middleware.md)| ✅ completado | Migrar funciones de I/O y ejecución a `middleware/` |
| 04 | [task_04_app.md](task_04_app.md)             | ✅ completado | Migrar TUI (Model, Update, View, renders) a `app/` |
| 05 | [task_05_utils.md](task_05_utils.md)         | ✅ completado | Split `utils/`: `icons.go` → `core/`, `platform.go` → `middleware/` |
| 06 | [task_06_cleanup.md](task_06_cleanup.md)     | ✅ completado | Eliminar paquetes legacy (`models/`, `utils/`) y limpiar `ui/` |
| 07 | [task_07_main.md](task_07_main.md)           | ✅ completado | Actualizar `main.go` con nuevos imports |
| 08 | [task_08_validation.md](task_08_validation.md)| ✅ completado | Build final, checks de imports cruzados, test funcional manual |

## Mapa de responsabilidades final

```
core/
  types.go       → Script, Category, ViewState (structs, sin métodos con I/O)
  sorting.go     → sortCategories, sortScripts (lógica de ordenamiento pura)
  gradient.go    → ApplyGradient (pura: toma []string, devuelve string)
  icons.go       → CategoryIcon, CategoryDescription (lookup maps puros)
  commands.go    → longestCommonPrefix, splitCommandAndArg, pure autocomplete logic

middleware/
  scanner.go     → ScanCategories, ScanScripts (lee filesystem)
  reader.go      → extractDescription, readmeFolderMeta, ReadLauncherVersion (lee archivos)
  executor.go    → ExecuteScript, buildScriptCommand (ejecuta procesos)
  assets.go      → LoadASCIIArt (lee archivos de static/)
  platform.go    → GetScriptsPath, GetStaticPath (resolución de paths del SO)

app/
  model.go       → Model struct, NewModel, Init, Update
  messages.go    → tipos Tea msg + factories (loadCategories, loadScripts, executeScript)
  views.go       → renderCategoryView, renderScriptView, renderResultView, renderExecutingView
  lists.go       → categoryItem, scriptItem, createCategoryList, createScriptList
  command_mode.go→ CommandMode struct, HandleCommand, SetSize, View, AutoComplete

ui/   (sin cambios de contenido, solo limpieza)
  styles.go      → todos los lipgloss styles y constantes Box*
  utils.go       → DrawSeparator, RenderBreadcrumb, RenderFallbackHeader
```

## Estado de los estados

- ⬜ pendiente
- 🔄 en progreso
- ✅ completado
- ❌ bloqueado
