````markdown
# Task 03 – Migrar funciones impuras a `middleware/`

**Estado:** ⬜ pendiente  
**Depende de:** task_02  
**Bloquea:** task_04

## Objetivo

Mover a `middleware/` todas las funciones que interactúan con el sistema real: lectura/escritura de archivos, configuración del shell, creación de shortcuts, generación de scripts.

## Movimientos por archivo

### `middleware/detection.go`
Mover desde `installer/core.go`:
- `func DetectExistingInstall(installDir string) (*core.ExistingInstall, error)`

Cambios:
- Importar `core` y usar `core.ExistingInstall` y `core.ParseVersion` en vez de los tipos locales.

```go
func DetectExistingInstall(installDir string) (*core.ExistingInstall, error)
```

### `middleware/extractor.go`
Mover desde `installer/core.go`:
- `func ExtractAssets(fsys embed.FS, destDir string, progress func(current, total int, filename string)) error`
- `func RemoveInstallDir(installDir string) error`

Cambios:
- Usar `core.CountAssets`, `core.MapAssetPath`, `core.IsExecutable` en lugar de las funciones locales.

```go
func ExtractAssets(fsys embed.FS, destDir string, progress func(current, total int, filename string)) error
func RemoveInstallDir(installDir string) error
```

### `middleware/shell_unix.go`  `(//go:build linux || darwin)`
Mover desde `installer/shell_unix.go`:
- `func ConfigureShell(installDir string) (string, error)`
- `func RemoveShellConfig() (string, error)`
- `func detectRCFile() string`            → mantener privada
- `func buildUnixBlock(installDir string) string`  → mantener privada
- `func removeBlock(content, start, end string) string` → mantener privada

Sin cambios de firma. Este archivo ya es impuro (lee/escribe archivos), se mueve tal cual al nuevo paquete.

### `middleware/shell_windows.go`  `(//go:build windows)`
Mover desde `installer/shell_windows.go` equivalente:
- `func ConfigureShell(installDir string) (string, error)`
- `func RemoveShellConfig() (string, error)`

### `middleware/shortcut_unix.go`  `(//go:build linux || darwin)`
Mover desde `installer/shortcut_unix.go`:
- `func CreateDesktopShortcut(installDir string) (string, error)`

Cambios:
- Usar `core.GetLauncherPath(installDir)` en vez de llamar a la función del paquete `installer`.

### `middleware/shortcut_windows.go`  `(//go:build windows)`
Mover desde `installer/shortcut_windows.go` equivalente:
- `func CreateDesktopShortcut(installDir string) (string, error)`

### `middleware/uninstaller_unix.go`  `(//go:build linux || darwin)`
Mover desde `installer/uninstaller_unix.go`:
- `func GenerateUninstaller(installDir string) error`

Sin cambios de firma.

### `middleware/uninstaller_windows.go`  `(//go:build windows)`
Mover desde `installer/uninstaller_windows.go` equivalente:
- `func GenerateUninstaller(installDir string) error`

## Criterio de éxito

```bash
cd installer-go && go build ./...
```
- Compila sin errores.
- `installer/` y `tui/` aún existen con sus implementaciones originales.
- `middleware/` tiene las nuevas implementaciones que usan tipos de `core/`.

## Reglas de capas

- `middleware/` **puede** importar `core/`.
- `middleware/` **NO puede** importar `tui/`, `installer/` ni `app/`.
- No usar variables globales. Pasar `installDir` y dependencias como parámetros explícitos.
````
