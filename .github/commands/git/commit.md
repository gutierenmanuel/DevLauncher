# Command: commit

Usa este comando para cerrar una tarea con sincronización y registro en git.

## Flujo obligatorio

1. Verificar rama y estado:

```bash
git branch --show-current
git status --short
```

2. Sincronizar antes de confirmar cambios:

```bash
git pull --rebase
```

3. Revisar diff y validar que solo incluya cambios de la tarea:

```bash
git diff --stat
git diff
```

4. Preparar archivos y hacer commit:

```bash
git add <archivos>
git commit -m "<tipo>: <resumen corto>"
```

## Convención de mensaje sugerida

- `feat: ...` nueva funcionalidad
- `fix: ...` corrección
- `refactor: ...` cambios estructurales
- `docs: ...` documentación
- `chore: ...` mantenimiento

## Checklist rápido

- [ ] `git pull --rebase` ejecutado sin conflictos.
- [ ] Solo cambios relacionados en el commit.
- [ ] Mensaje de commit claro y corto.
