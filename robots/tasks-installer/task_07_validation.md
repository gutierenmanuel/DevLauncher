````markdown
# Task 07 – Validación final

**Estado:** ⬜ pendiente  
**Depende de:** task_06  
**Bloquea:** nada (última tarea)

## Objetivo

Verificar que la refactorización está completa, los binarios compilan correctamente y la arquitectura respeta las reglas de capas definidas.

## Checklist de validación

### Build

```bash
cd installer-go
go build ./...
go build -o installer .
go build -o cmd/uninstaller/uninstaller ./cmd/uninstaller/
```

- [ ] `go build ./...` sin errores
- [ ] Binario `installer` generado correctamente
- [ ] Binario `uninstaller` generado correctamente

### Verificación de capas (imports prohibidos)

```bash
cd installer-go

# core/ NO debe importar middleware/, app/, installer/, tui/
grep -r '"github.com/lucas/installer/middleware"' core/
grep -r '"github.com/lucas/installer/app"' core/
grep -r '"github.com/lucas/installer/installer"' core/
# Resultado esperado: sin output (0 matches)

# middleware/ NO debe importar app/, installer/, tui/
grep -r '"github.com/lucas/installer/app"' middleware/
grep -r '"github.com/lucas/installer/installer"' middleware/
grep -r '"github.com/lucas/installer/tui"' middleware/
# Resultado esperado: sin output (0 matches)

# app/ NO debe importar installer/, tui/
grep -r '"github.com/lucas/installer/installer"' app/
grep -r '"github.com/lucas/installer/tui"' app/
# Resultado esperado: sin output (0 matches)

# main.go y cmd/ NO deben importar installer/ ni tui/
grep '"github.com/lucas/installer/installer"' main.go cmd/uninstaller/main.go
grep '"github.com/lucas/installer/tui"' main.go cmd/uninstaller/main.go
# Resultado esperado: sin output (0 matches)
```

### Paquetes legacy eliminados

```bash
ls installer-go/installer/ 2>/dev/null && echo "ERROR: installer/ aún existe"
ls installer-go/tui/ 2>/dev/null && echo "ERROR: tui/ aún existe"
# Resultado esperado: ambos comandos producen "No such file or directory"
```

### Funcionalidad manual (installer)

- [ ] `./installer` → abre TUI splash screen del installer
- [ ] Flujo completo: detección → confirmación → instalación → shell config → desktop shortcut → done
- [ ] Pantalla de error se muestra correctamente si falla algo

### Funcionalidad manual (uninstaller)

- [ ] `./cmd/uninstaller/uninstaller` → abre TUI splash del uninstaller
- [ ] Flujo completo: detección → confirmación → eliminación → limpieza shell → done
- [ ] Caso `NotFound` se muestra si no hay instalación

### Verificación de estructura final

```
installer-go/
  core/         → ✅ solo stdlib sin I/O real (excepto os.UserHomeDir)
  middleware/   → ✅ os.*, io/fs.*, embed permitidos
  app/          → ✅ bubbletea, core, middleware importados; NO installer/ ni tui/
  main.go       → ✅ importa solo app/
  cmd/
    uninstaller/
      main.go   → ✅ importa solo app/
  embed.go      → ✅ sin cambios
  go.mod        → ✅ sin cambios de module path
```

## Build de producción (opcional)

```bash
cd installer-go
./build-installer.sh    # Linux/macOS
# ./build-installer.ps1 # Windows
```

- [ ] Binarios de producción generados
- [ ] Funciona correctamente en sistema limpio

## Notas

- Si algún check falla, identificar en qué tarea quedó incompleto y volver a esa tarea.
- En caso de imports circulares, revisar que `core/` no importe nada de `middleware/` o `app/`.
````
