# Task 05 – Split `utils/` → `core/` y `middleware/`

**Estado:** ⬜ pendiente  
**Depende de:** task_02, task_03  
**Bloquea:** task_06

## Objetivo

Disolver el paquete `utils/` distribuyendo sus archivos según su naturaleza:
- `icons.go` → funciones puras de lookup → ya fue a `core/` en task_02
- `platform.go` → resolución de paths del SO → ya fue a `middleware/` en task_03

## Verificación

En esta tarea solo se confirma que los movimientos previos cubrieron todo `utils/`:

### `utils/icons.go` — contenido esperado ya en `core/icons.go`:
- `CategoryIcon(name string) string` ✅
- `CategoryDescription(name string) string` ✅

### `utils/platform.go` — contenido esperado ya en `middleware/platform.go`:
- `GetScriptsPath(rootDir string) string` ✅
- `GetStaticPath(rootDir string) string` ✅

## Actualización de imports en `models/` existente

En esta tarea, actualizar los imports en `models/` (que aún quedará hasta task_06) para que dejen de depender de `utils/` y usen `core/` y `middleware/` según corresponda.

Esto permite que en task_06 se pueda eliminar `utils/` sin romper nada.

## Criterio de éxito

```bash
cd launcher-go && go build ./...
```
- Compila sin errores.
- No hay referencias a `github.com/lucas/launcher/utils` en ningún archivo de `core/`, `middleware/` ni `app/`.

## Notas

- Si `models/` aún importa `utils/` (por ser legacy), está permitido temporalmente.
- El import `utils/` se elimina completamente en task_06 junto con el paquete.
