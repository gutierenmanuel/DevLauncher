# Commands (DevLauncher)

Esta carpeta centraliza comandos reutilizables para flujos de trabajo comunes.

## Estructura

- `git/push.md` → flujo de commits por bloques + push seguro y consistente.
- `init/workspace.md` → inicialización de workspace (`init: workspace`).

## Comandos disponibles

### `git push`

Ubicación: `commands/git/push.md`

Objetivo:

1. Sincronizar rama con remoto (`git pull`).
2. Separar cambios en varios commits si son de distinta naturaleza.
3. Escribir descripciones largas en español para cada commit.
4. Publicar al remoto (`git push`).

### `init: workspace`

Ubicación: `commands/init/workspace.md`

Objetivo:

1. Detectar stack/proyecto.
2. Crear estructura base mínima.
3. Dejar comandos de build/run documentados.
