# Task 02 – Migrar funciones puras a `core/`

**Estado:** ⬜ pendiente  
**Depende de:** task_01  
**Bloquea:** task_03, task_04

## Objetivo

Mover a `core/` todas las funciones y tipos que son **completamente puros** (sin I/O, sin `os.*`, sin `exec.*`, sin estado global mutable).

## Movimientos por archivo

### `core/types.go`
Mover desde `models/`:
- `type Script struct`
- `type Category struct`
- `type ViewState int` + constantes `CategoryView`, `ScriptView`, `ExecutingView`, `ResultView`

### `core/sorting.go`
Extraer desde `models/category.go` y `models/script.go`:
- Lógica de `sort.Slice` para categorías (alfabético)
- Lógica de `sort.Slice` para scripts (dirs primero, luego alfabético)

Firmas target:
```go
func SortCategories(cats []Category) []Category
func SortScripts(scripts []Script) []Script
```

### `core/gradient.go`
Mover desde `ui/views.go`:
- `func ApplyGradient(lines []string) string`

No mover:
- `LoadASCIIArt` → tiene I/O, va a `middleware/`

### `core/icons.go`
Mover desde `utils/icons.go`:
- `func CategoryIcon(name string) string`
- `func CategoryDescription(name string) string`

### `core/commands.go`
Extraer desde `models/command.go`:
- `func longestCommonPrefix(words []string) string`
- `func splitCommandAndArg(input string) (cmd, arg string, ok bool)`
- `var commandSuggestions = []string{...}`
- Lógica de autocompletado que solo opera sobre strings (sin filesystem)

## Criterio de éxito

```bash
cd launcher-go && go build ./...
```
- Compila sin errores.
- `models/`, `ui/`, `utils/` aún existen y sus imports siguen funcionando.
- Los nuevos archivos en `core/` están importables pero aún no son usados por nadie.

## Notas

- En esta tarea solo se **crea** código en `core/`. No se elimina nada de `models/`.
- Si una función en `models/` usa tipos que se movieron a `core/`, agregar alias temporales o mantener ambas definiciones hasta task_06 (cleanup).
- Asegurar que `core/` no importe `models/`, `ui/`, `utils/` ni paquetes del OS.
