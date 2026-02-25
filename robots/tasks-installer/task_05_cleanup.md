````markdown
# Task 05 – Limpiar paquetes legacy

**Estado:** ⬜ pendiente  
**Depende de:** task_04  
**Bloquea:** task_06

## Objetivo

Eliminar los paquetes `installer/` y `tui/` una vez que todo su contenido ha sido migrado a `core/`, `middleware/` y `app/`.

## Pre-condición

Antes de eliminar, verificar que ningún archivo fuera de `installer/` y `tui/` los importa:

```bash
cd installer-go

# Verificar que main.go ya NO importa installer/ ni tui/
grep -r '"github.com/lucas/installer/installer"' .
grep -r '"github.com/lucas/installer/tui"' .
# Resultado esperado: sin output (0 matches fuera de los propios paquetes)
```

Si algún archivo externo aún los importa, **no continuar**: actualizar esos imports primero.

## Archivos a eliminar

```
installer-go/
  installer/    → eliminar carpeta completa
    core.go
    shell_unix.go
    shell_windows.go
    shortcut_unix.go
    shortcut_windows.go
    uninstaller_unix.go
    uninstaller_windows.go

  tui/          → eliminar carpeta completa
    model.go
    styles.go
    uninstaller.go
```

## Comandos

```bash
cd installer-go
rm -rf installer/
rm -rf tui/
```

## Criterio de éxito

```bash
cd installer-go && go build ./...
```
- Compila sin errores.
- `installer/` no existe.
- `tui/` no existe.
- Toda la lógica vive en `core/`, `middleware/`, `app/`.

## Notas

- Si hay duda sobre si algo fue migrado completamente, hacer `grep -r "TODO\|FIXME" core/ middleware/ app/` antes de eliminar.
- Solo eliminar si el build es exitoso antes de la eliminación.
````
