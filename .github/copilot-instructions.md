# Copilot Instructions (DevLauncher)

## Uso obligatorio del índice de prompts

- Antes de responder tareas no triviales, consulta `prompts/index.md`.
- Selecciona el prompt más adecuado según el tipo de tarea (scripts, docs, build, UX, etc.).
- Si existe un prompt específico para la tarea, úsalo como guía principal.
- Si no existe, aplica las reglas generales del repositorio y propone crear un nuevo prompt en `prompts/`.

## Flujo recomendado para cada solicitud

1. Clasificar la tarea (implementación, documentación, validación, refactor, etc.).
2. Revisar `prompts/index.md` y elegir el prompt aplicable.
3. Ejecutar la tarea alineado a ese prompt y al estilo del repo.
4. Validar cambios (build/tests cuando aplique).
5. Reportar qué se cambió y qué prompt del índice se usó.

## Convenciones de mantenimiento del índice

- Cada nuevo archivo en `prompts/*.md` debe añadirse en `prompts/index.md`.
- Mantener descripciones cortas y orientadas a cuándo usar cada prompt.
- Evitar duplicar prompts con objetivos idénticos.

## Prioridad de instrucciones

1. Solicitud del usuario.
2. `prompts/index.md` + prompt específico seleccionado.
3. Estas instrucciones de `copilot-instructions.md`.
4. Convenciones existentes del código/documentación.
