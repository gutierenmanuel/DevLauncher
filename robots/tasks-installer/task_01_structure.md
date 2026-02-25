````markdown
# Task 01 – Crear estructura de carpetas

**Estado:** ⬜ pendiente  
**Depende de:** nada  
**Bloquea:** task_02, task_03, task_04

## Objetivo

Crear las carpetas `core/`, `middleware/` y `app/` dentro de `installer-go/` con archivos `.go` stub (solo declaración de paquete) para que Go no rompa el build por paquetes vacíos.

## Archivos a crear

```
installer-go/
  core/
    version.go     → package core
    assets.go      → package core
    paths.go       → package core
    types.go       → package core

  middleware/
    detection.go        → package middleware
    extractor.go        → package middleware
    shell_unix.go       → package middleware  (//go:build linux || darwin)
    shell_windows.go    → package middleware  (//go:build windows)
    shortcut_unix.go    → package middleware  (//go:build linux || darwin)
    shortcut_windows.go → package middleware  (//go:build windows)
    uninstaller_unix.go    → package middleware  (//go:build linux || darwin)
    uninstaller_windows.go → package middleware  (//go:build windows)

  app/
    styles.go            → package app
    types.go             → package app
    messages.go          → package app
    model.go             → package app
    views.go             → package app
    uninstaller.go       → package app
    uninstaller_views.go → package app
```

## Criterio de éxito

```bash
cd installer-go && go build ./...
```
Compila sin errores. Los stubs no rompen nada porque aún no son importados.

## Notas

- Los stubs son solo `package <nombre>`, sin imports ni funciones.
- Los archivos con build tags deben incluir la directiva correspondiente en la primera línea.
- El código actual en `installer/` y `tui/` NO se toca en esta tarea.
````
