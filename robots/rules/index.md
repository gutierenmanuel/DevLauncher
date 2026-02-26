# Índice de Rules (DevLauncher)

Este índice centraliza qué rule usar según la tarea.

## Rules disponibles

- `nuevos_scripts.md`
  - **Usar cuando:** se creen o modifiquen scripts (`.sh`, `.ps1`, `.bat`) y se necesiten reglas de integración con el launcher.
  - **Cubre:** pausas con input, selección numérica, códigos de salida, metadatos para el launcher, estructura por carpetas.

- `nuevas_rules.md`
  - **Usar cuando:** se cree o actualice documentación de rules dentro de `robots/rules/`.
  - **Cubre:** criterio para crear rules nuevas, estructura recomendada, estilo, mantenimiento y actualización obligatoria del índice.

- `nuevas_carpetas.md`
  - **Usar cuando:** se creen categorías o subcarpetas nuevas en `scripts/linux` o `scripts/win`.
  - **Cubre:** reglas de detección en launcher, metadatos por `README`, iconos, descripciones y checklist de integración.

- `arreglar_scripts.md`
  - **Usar cuando:** se corrija un script existente (`.sh`, `.ps1`, `.bat`) y se deba evitar que el fallo reaparezca.
  - **Cubre:** flujo de diagnóstico, corrección mínima, test de regresión obligatorio por bug, validación local y checklist de cierre.

- `nuevos_tests.md`
  - **Usar cuando:** se creen o modifiquen tests de scripts, incluyendo regresiones.
  - **Cubre:** ubicación obligatoria en `scripts/win/configuracion_devlauncher/tests/`, validación funcional real, y mocking de operaciones con side effects para no afectar el sistema.

- `integracion_llm.md`
  - **Usar cuando:** se quiera que un LLM navegue menús, seleccione scripts y ejecute flujos de DevLauncher de forma determinista.
  - **Cubre:** contrato CLI/JSON (`--menu-json`, `--run`, `--json`), desambiguación de scripts, trazabilidad de ejecución y formato de respuesta para agentes.

## Regla rápida de selección

1. Identifica el tipo de tarea.
2. Elige la rule más específica en esta lista.
3. Si no existe una adecuada, seguir convenciones del repo y proponer crear una nueva rule.
