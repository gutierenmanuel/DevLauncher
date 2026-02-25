# Task 07 – Actualizar `main.go`

**Estado:** ⬜ pendiente  
**Depende de:** task_06  
**Bloquea:** task_08

## Objetivo

Actualizar `main.go` para que use el nuevo paquete `app/` en vez del eliminado `models/`.

## Cambios en `main.go`

### Import actual:
```go
import (
    "fmt"
    "os"

    tea "github.com/charmbracelet/bubbletea"
    "github.com/lucas/launcher/models"
)
```

### Import nuevo:
```go
import (
    "fmt"
    "os"

    tea "github.com/charmbracelet/bubbletea"
    "github.com/lucas/launcher/app"
)
```

### Cambios de llamadas:

| Antes | Después |
|-------|---------|
| `models.NewModel()` | `app.NewModel()` |
| `models.ListAllScripts()` | `app.ListAllScripts()` |

## Resultado esperado de `main.go`

```go
package main

import (
    "fmt"
    "os"

    tea "github.com/charmbracelet/bubbletea"
    "github.com/lucas/launcher/app"
)

func main() {
    if len(os.Args) > 1 {
        switch os.Args[1] {
        case "-h", "--help":
            showHelp()
            return
        case "-l", "--list":
            app.ListAllScripts()
            return
        default:
            fmt.Printf("Unknown option: %s\n", os.Args[1])
            fmt.Println("Use --help to see available options")
            os.Exit(1)
        }
    }

    model := app.NewModel()
    p := tea.NewProgram(&model, tea.WithAltScreen(), tea.WithMouseAllMotion())
    if _, err := p.Run(); err != nil {
        fmt.Printf("Error: %v\n", err)
        os.Exit(1)
    }
}

func showHelp() {
    // sin cambios
}
```

## Criterio de éxito

```bash
cd launcher-go && go build ./...
```
Compila sin errores ni warnings.
