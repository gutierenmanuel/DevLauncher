# Índice de Prompts (DevLauncher)

Este índice centraliza qué prompt usar según la tarea.

## Prompts disponibles

- `nuevos_scripts.md`
  - **Usar cuando:** se creen o modifiquen scripts (`.sh`, `.ps1`, `.bat`) y se necesiten reglas de integración con el launcher.
  - **Cubre:** pausas con input, selección numérica, códigos de salida, metadatos para el launcher, estructura por carpetas.

- `nuevos_prompts.md`
  - **Usar cuando:** se cree o actualice documentación de prompts dentro de `prompts/`.
  - **Cubre:** criterio para crear prompts nuevos, estructura recomendada, estilo, mantenimiento y actualización obligatoria del índice.

- `nuevas_carpetas.md`
  - **Usar cuando:** se creen categorías o subcarpetas nuevas en `scripts/linux` o `scripts/win`.
  - **Cubre:** reglas de detección en launcher, metadatos por `README`, iconos, descripciones y checklist de integración.

- `arreglar_scripts.md`
  - **Usar cuando:** se corrija un script existente (`.sh`, `.ps1`, `.bat`) y se deba evitar que el fallo reaparezca.
  - **Cubre:** flujo de diagnóstico, corrección mínima, test de regresión obligatorio por bug, validación local y checklist de cierre.

- `nuevos_tests.md`
  - **Usar cuando:** se creen o modifiquen tests de scripts, incluyendo regresiones.
  - **Cubre:** ubicación obligatoria en `scripts/win/configuracion_devlauncher/tests/`, validación funcional real, y mocking de operaciones con side effects para no afectar el sistema.

## Regla rápida de selección

1. Identifica el tipo de tarea.
2. Elige el prompt más específico en esta lista.
3. Si no existe uno adecuado, seguir convenciones del repo y proponer crear un nuevo prompt.
