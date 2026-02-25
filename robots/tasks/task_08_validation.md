# Task 08 – Validación final

**Estado:** ⬜ pendiente  
**Depende de:** task_07  
**Bloquea:** nada (última tarea)

## Objetivo

Verificar que la refactorización está completa, el binario funciona correctamente y la arquitectura respeta las reglas de capas.

## Checklist de validación

### Build

```bash
cd launcher-go
go build ./...
go build -o launcher .
```

- [ ] Compila sin errores
- [ ] Compila sin warnings

### Verificación de capas (imports prohibidos)

```bash
# core/ NO debe importar middleware/, app/, models/, utils/, ui/
grep -r '"github.com/lucas/launcher/middleware"' core/
grep -r '"github.com/lucas/launcher/app"' core/
grep -r '"github.com/lucas/launcher/models"' core/
# Resultado esperado: sin output (0 matches)

# middleware/ NO debe importar app/, models/
grep -r '"github.com/lucas/launcher/app"' middleware/
grep -r '"github.com/lucas/launcher/models"' middleware/
# Resultado esperado: sin output (0 matches)

# app/ NO debe importar models/, utils/
grep -r '"github.com/lucas/launcher/models"' app/
grep -r '"github.com/lucas/launcher/utils"' app/
# Resultado esperado: sin output (0 matches)
```

### Funcionalidad manual

- [ ] `./launcher` → abre TUI, navega categorías correctamente
- [ ] `./launcher --list` → lista scripts por categoría
- [ ] `./launcher --help` → muestra ayuda
- [ ] Ejecutar un script `.sh` → resultado visible con scroll
- [ ] Modo comando (`:`) → funciona autocompletado y `cd`, `ls`, `pwd`
- [ ] Navegar subcarpetas → breadcrumb correcto
- [ ] ASCII art random en CategoryView → se muestra con gradiente

### Verificación de estructura final

```
launcher-go/
  core/         → ✅ solo tipos Go estándar y stdlib sin I/O
  middleware/   → ✅ os.*, exec.*, io.* permitidos
  app/          → ✅ bubbletea, core, middleware, ui importados
  ui/           → ✅ solo lipgloss styles + helpers de render puros
  main.go       → ✅ importa solo app/
  go.mod        → ✅ sin cambios de módulo (module path igual)
```

### Estructura de directorios eliminada

- [ ] `models/` → no existe
- [ ] `utils/` → no existe

## Build de producción (opcional)

```bash
cd launcher-go
./build.sh    # Linux/macOS
```

- [ ] Binario `launcher` generado en `outputs/` o path configurado
- [ ] Funciona correctamente en producción

## Actualizar `robots/tasks/index.md`

Marcar todas las tareas como ✅ completado en el índice.
