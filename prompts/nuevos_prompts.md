# Nuevos prompts en DevLauncher

Usa estas reglas cuando crees un archivo nuevo en `prompts/`.

## 1) Cuándo crear un prompt nuevo

Crea un prompt nuevo solo si:

- hay una tarea repetida que no está bien cubierta por un prompt existente,
- necesitas reglas específicas por tipo de trabajo (scripts, docs, build, UX, etc.),
- el flujo requiere checklist propio para evitar errores frecuentes.

Si el objetivo ya está cubierto, amplía el prompt existente en lugar de duplicar contenido.

## 2) Nombre del archivo

- Formato recomendado: `nuevos_<tema>.md`.
- Nombre en minúsculas, con guiones bajos y sin espacios.
- Debe describir claramente cuándo usarlo.

Ejemplos:

- `nuevos_scripts.md`
- `nuevas_carpetas.md`

## 3) Estructura mínima del prompt

Todo prompt nuevo debería incluir:

1. **Objetivo**: para qué existe.
2. **Cuándo usarlo**: casos concretos.
3. **Reglas obligatorias**: decisiones no negociables.
4. **Checklist final**: validación rápida antes de cerrar cambios.

Mantén el contenido accionable y orientado a ejecución, no teoría.

## 4) Estilo y consistencia

- Mensajes y ejemplos en español, claros y cortos.
- Reglas en formato de pasos/listas.
- Evitar contradicciones con `copilot-instructions.md` y prompts existentes.
- Si una regla aplica a varias áreas, enlazarla en el índice en vez de duplicarla.

## 5) Integración obligatoria con el índice

Cada nuevo archivo en `prompts/` debe añadirse en `prompts/index.md` con:

- nombre de archivo,
- cuándo usarlo,
- qué cubre.

Si no está en el índice, se considera incompleto.

## 6) Evolución y mantenimiento

- Si cambian convenciones del repo, actualiza primero el prompt afectado.
- Evita crear prompts casi idénticos; fusiona cuando sea posible.
- En cambios grandes, añade una mini sección de “errores comunes” si aporta valor.

## 7) Checklist rápido

- [ ] El problema no está cubierto por otro prompt existente.
- [ ] El nombre del archivo es claro y consistente.
- [ ] El prompt tiene objetivo, uso, reglas y checklist.
- [ ] No contradice instrucciones del repositorio.
- [ ] Se agregó/actualizó entrada en `prompts/index.md`.
