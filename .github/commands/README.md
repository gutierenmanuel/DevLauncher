# Commands (DevLauncher)

Esta carpeta centraliza comandos reutilizables para flujos de trabajo comunes.

## Estructura

- `git/commit.md` → flujo de commit seguro y consistente.
- `init/workspace.md` → inicialización de workspace (`init: workspace`).

## Comandos disponibles

### `commit`

Ubicación: `commands/git/commit.md`

Objetivo:

1. Sincronizar rama con remoto (`git pull`).
2. Revisar cambios.
3. Crear commit con mensaje claro.

### `init: workspace`

Ubicación: `commands/init/workspace.md`

Objetivo:

1. Detectar stack/proyecto.
2. Crear estructura base mínima.
3. Dejar comandos de build/run documentados.
