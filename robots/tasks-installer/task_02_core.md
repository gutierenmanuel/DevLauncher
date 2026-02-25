````markdown
# Task 02 – Migrar funciones puras a `core/`

**Estado:** ⬜ pendiente  
**Depende de:** task_01  
**Bloquea:** task_03, task_04

## Objetivo

Mover a `core/` todas las funciones y tipos que son **completamente puros**: sin I/O, sin `os.*` (excepto `os.UserHomeDir` que es determinista), sin efectos secundarios, sin estado global mutable.

## Movimientos por archivo

### `core/types.go`
Mover desde `installer/core.go`:
- `type ExistingInstall struct { Dir, Version string }`

Mover desde `tui/model.go`:
- `type Phase int` + constantes `PhaseSplash`, `PhaseDetecting`, `PhaseConfirm`, `PhaseInstalling`, `PhaseShellConfig`, `PhaseDesktopShortcut`, `PhaseDone`, `PhaseError`

Mover desde `tui/uninstaller.go`:
- `type UninstallPhase int` + constantes `UninstallPhaseSplash` ... `UninstallPhaseNotFound`

### `core/version.go`
Mover desde `installer/core.go`:
- `func ParseVersion(content string) string`
- `func CompareVersions(a, b string) int`
- `func parseParts(v string) [3]int`

Firmas target (sin cambios):
```go
func ParseVersion(content string) string
func CompareVersions(a, b string) int
```

### `core/assets.go`
Mover desde `installer/core.go`:
- `func CountAssets(fsys embed.FS) int`
- `func mapAssetPath(embPath, destDir string) string`
- `func isExecutable(path string) bool`

Nota: `CountAssets` interactúa con `embed.FS` pero es determinista y sin efectos secundarios (solo lee el FS embebido, no el filesystem real). Clasificar como pura.

Firmas target:
```go
func CountAssets(fsys embed.FS) int
func MapAssetPath(embPath, destDir string) string   // exportar
func IsExecutable(path string) bool                 // exportar
```

### `core/paths.go`
Mover desde `installer/core.go`:
- `func GetInstallDir() string`     → usa `os.UserHomeDir()` pero es determinista
- `func GetLauncherPath(installDir string) string`

Firmas target (sin cambios):
```go
func GetInstallDir() string
func GetLauncherPath(installDir string) string
```

## Criterio de éxito

```bash
cd installer-go && go build ./...
```
- Compila sin errores.
- `installer/` y `tui/` aún existen y sus imports siguen funcionando.
- Los nuevos archivos en `core/` son importables pero aún no usados por nadie.

## Notas

- En esta tarea solo se **crea** código en `core/`. No se elimina nada de `installer/` ni `tui/`.
- `core/` solo puede importar paquetes de stdlib que no generen efectos: `strings`, `strconv`, `embed`, `io/fs`, `runtime`, `path/filepath`, `os` (solo `UserHomeDir`).
- No importar `core/` desde `installer/` todavía.
````
