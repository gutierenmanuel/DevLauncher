# Task 03 – Migrar funciones impuras a `middleware/`

**Estado:** ⬜ pendiente  
**Depende de:** task_02  
**Bloquea:** task_04

## Objetivo

Mover a `middleware/` todas las funciones que interactúan con el sistema (filesystem, I/O de archivos, ejecución de procesos, detección del SO).

## Movimientos por archivo

### `middleware/scanner.go`
Mover desde `models/category.go` y `models/script.go`:
- `func ScanCategories(rootDir string) ([]core.Category, error)`
- `func ScanScripts(categoryPath string) ([]core.Script, error)`
- `func countImmediateItems(folderPath, platform string) (int, int)`

**Cambios:** usar `core.Category`, `core.Script` en vez de los tipos locales de `models/`.  
Usar `core.SortCategories`, `core.SortScripts` para ordenar.

### `middleware/reader.go`
Mover desde `models/category.go` y `models/script.go`:
- `func extractDescription(scriptPath string) string`
- `func readmeFolderMeta(folderPath string) (icon, desc string, ok bool)`
- `func folderIconFromREADME(folderPath, fallback string) string`
- `func folderDescriptionFromREADME(folderPath, fallback string) string`

Mover desde `models/app.go`:
- `func readLauncherVersion(rootDir string) string`  → renombrar a `ReadLauncherVersion`

### `middleware/executor.go`
Mover desde `models/executor.go`:
- `func buildScriptCommand(script core.Script, workingDir string) *exec.Cmd`  
  (renombrar `getScriptCommand` → `buildScriptCommand` para hacer la API pública)
- `func ExecuteScript(script core.Script, workingDir string) (int, string)`

Eliminar la duplicación: `executor.go` actual tiene `getScriptCommand` y `ExecuteScript` con el mismo switch. Unificar: `ExecuteScript` usa `buildScriptCommand` internamente.

### `middleware/assets.go`
Mover desde `ui/views.go`:
- `func LoadASCIIArt(staticPath string) string`

Usa `core.ApplyGradient` internally en vez de duplicar la lógica de gradiente.

### `middleware/platform.go`
Mover desde `utils/platform.go`:
- `func GetScriptsPath(rootDir string) string`
- `func GetStaticPath(rootDir string) string`

## Criterio de éxito

```bash
cd launcher-go && go build ./...
```
- Compila sin errores.
- `models/`, `ui/`, `utils/` aún existen con sus implementaciones originales.
- `middleware/` tiene las nuevas implementaciones que usan tipos de `core/`.

## Notas

- `middleware/` puede importar `core/` pero NO `models/`, `ui/` ni `utils/`.
- Pasar dependencias como parámetros, no usar variables globales.
- `middleware/scanner.go` usa `middleware/reader.go` internamente (mismo paquete, sin problema).
