# Command: git push

Usa este comando para cerrar una tarea completa con sincronización, commits por bloques de cambio y publicación al remoto.

## Flujo obligatorio

1. Verificar rama y estado:

```bash
git branch --show-current
git status --short
```

2. Sincronizar antes de preparar commits:

```bash
git pull --rebase
```

3. Revisar cambios y separarlos por tema:

```bash
git diff --stat
git diff
```

4. Si hay cambios de distinta naturaleza, crear varios commits:

- Commit 1: refactor/código
- Commit 2: documentación
- Commit 3: reglas/configuración

Comandos sugeridos:

```bash
git add <archivos_del_bloque_1>
git commit -m "<tipo>: <resumen breve>" -m "Descripción larga en español explicando qué cambia, por qué se hizo, impacto esperado y alcance del bloque."

git add <archivos_del_bloque_2>
git commit -m "<tipo>: <resumen breve>" -m "Descripción larga en español explicando qué cambia, por qué se hizo, impacto esperado y alcance del bloque."
```

5. Publicar commits:

```bash
git push
```

## Convención de commits

- `feat:` nueva funcionalidad
- `fix:` corrección de error
- `refactor:` cambio estructural sin cambio funcional
- `docs:` documentación
- `chore:` mantenimiento

## Regla de mensajes

- El título (`-m` corto) debe resumir el bloque.
- El cuerpo (`-m` largo) debe estar en español y explicar:
	- qué se cambió,
	- por qué se cambió,
	- qué impacto tiene,
	- qué no se tocó.

## Checklist rápido

- [ ] `git pull --rebase` ejecutado sin conflictos.
- [ ] Se separaron cambios distintos en commits diferentes.
- [ ] Cada commit tiene descripción larga en español.
- [ ] `git push` ejecutado correctamente.
