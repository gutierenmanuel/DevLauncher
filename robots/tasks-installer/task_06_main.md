````markdown
# Task 06 – Actualizar entry points

**Estado:** ⬜ pendiente  
**Depende de:** task_05  
**Bloquea:** task_07

## Objetivo

Actualizar `main.go` del installer y `cmd/uninstaller/main.go` para que importen `app/` en lugar de los paquetes legacy eliminados.

## Cambios en `main.go` (installer)

**Import actual:**
```go
import (
    tea "github.com/charmbracelet/bubbletea"
    "github.com/lucas/installer/tui"
)
```

**Import nuevo:**
```go
import (
    tea "github.com/charmbracelet/bubbletea"
    "github.com/lucas/installer/app"
)
```

**Cambios de uso:**
```go
// Antes:
m := tui.NewModel(assetsFS)
p := tea.NewProgram(&m, tea.WithAltScreen())
// ...
if fm, ok := finalModel.(*tui.Model); ok { ... }
if fm, ok := finalModel.(tui.Model); ok { ... }

// Después:
m := app.NewModel(assetsFS)
p := tea.NewProgram(&m, tea.WithAltScreen())
// ...
if fm, ok := finalModel.(*app.Model); ok { ... }
if fm, ok := finalModel.(app.Model); ok { ... }
```

## Cambios en `cmd/uninstaller/main.go`

**Import actual:**
```go
import (
    tea "github.com/charmbracelet/bubbletea"
    "github.com/lucas/installer/tui"
)
```

**Import nuevo:**
```go
import (
    tea "github.com/charmbracelet/bubbletea"
    "github.com/lucas/installer/app"
)
```

**Cambios de uso:**
```go
// Antes:
m := tui.NewUninstallModel()

// Después:
m := app.NewUninstallModel()
```

## Criterio de éxito

```bash
cd installer-go
go build ./...
go build -o installer .
go build -o cmd/uninstaller/uninstaller ./cmd/uninstaller/
```
- Los tres comandos compilan sin errores.
- `main.go` no importa `tui/` ni `installer/`.
- `cmd/uninstaller/main.go` no importa `tui/` ni `installer/`.

## Notas

- `embed.go` no requiere cambios (solo declara el `//go:embed assets` y el `assetsFS`).
- Si `go.mod` tiene un `replace` o alias, verificar que el module path coincida.
````
