# Task 06 – Eliminar paquetes legacy

**Estado:** ⬜ pendiente  
**Depende de:** task_04, task_05  
**Bloquea:** task_07

## Objetivo

Eliminar los paquetes `models/` y `utils/`. Limpiar `ui/` dejando solo lo que pertenece allí (estilos puros + helpers de rendering sin I/O).

## Pasos

### 1. Eliminar `utils/`

```bash
rm launcher-go/utils/icons.go
rm launcher-go/utils/platform.go
rmdir launcher-go/utils
```

Verificar que no queden imports de `github.com/lucas/launcher/utils` en ningún archivo.

### 2. Depurar `ui/`

`ui/views.go` actualmente contiene:
- `LoadASCIIArt` → ya migrado a `middleware/assets.go` → **eliminar de ui/**
- `ApplyGradient` → ya migrado a `core/gradient.go` → **eliminar de ui/**
- `RenderFallbackHeader` → es función pura, moverla a `ui/` o `core/` — **mantener en ui/** (es renderizado UI puro)
- `RenderBreadcrumb` → puro también — **mantener en ui/utils.go**

Después de la limpieza, `ui/` queda:
```
ui/
  styles.go   → lipgloss styles y constantes Box* (sin cambios)
  utils.go    → DrawSeparator, RenderBreadcrumb, RenderFallbackHeader
```
El archivo `ui/views.go` se elimina o se vacía (su contenido migrado a `core/` y `middleware/`).

### 3. Eliminar `models/`

```bash
rm launcher-go/models/app.go
rm launcher-go/models/category.go
rm launcher-go/models/script.go
rm launcher-go/models/command.go
rm launcher-go/models/executor.go
rmdir launcher-go/models
```

Verificar que no queden imports de `github.com/lucas/launcher/models` en ningún archivo excepto `main.go` (que se actualiza en task_07).

## Criterio de éxito

```bash
cd launcher-go && go build ./...
```
- Puede fallar en `main.go` (porque sigue importando `models`) — **eso está bien**, se arregla en task_07.
- Todos los demás archivos compilan sin errores.

## Checklist de limpieza

- [ ] No quedan archivos en `utils/`
- [ ] No quedan archivos en `models/`
- [ ] `ui/` solo tiene `styles.go` y `utils.go`
- [ ] `go build ./core/...` → sin errores
- [ ] `go build ./middleware/...` → sin errores
- [ ] `go build ./app/...` → sin errores
