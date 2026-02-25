# Task 01 – Crear estructura de carpetas

**Estado:** ⬜ pendiente  
**Depende de:** nada  
**Bloquea:** task_02, task_03, task_04

## Objetivo

Crear las carpetas `core/`, `middleware/` y `app/` dentro de `launcher-go/` con archivos `.go` stub (package declaration únicamente) para que Go no rompa el build por paquetes vacíos.

## Archivos a crear

```
launcher-go/
  core/
    types.go        → package core
    sorting.go      → package core
    gradient.go     → package core
    icons.go        → package core
    commands.go     → package core

  middleware/
    scanner.go      → package middleware
    reader.go       → package middleware
    executor.go     → package middleware
    assets.go       → package middleware
    platform.go     → package middleware

  app/
    model.go        → package app
    messages.go     → package app
    views.go        → package app
    lists.go        → package app
    command_mode.go → package app
```

## Criterio de éxito

```bash
cd launcher-go && go build ./...
```
Compila sin errores (los stubs no rompen nada porque aún no son importados).

## Notas

- Los stubs son solo `package <nombre>`, sin imports ni funciones.
- El código actual en `models/`, `ui/`, `utils/` NO se toca en esta tarea.
