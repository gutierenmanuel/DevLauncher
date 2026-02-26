# Command: init: workspace

Usa este comando para inicializar un workspace nuevo de forma mínima y consistente.

## Objetivo

- Crear estructura base del proyecto.
- Dejar comandos de ejecución claros.
- Evitar configuración innecesaria para un primer arranque.

## Flujo recomendado

1. Identificar tipo de proyecto (Go, Python, Node, etc.).
2. Crear carpetas/archivos base mínimos.
3. Añadir README con instrucciones de `build` y `run`.
4. Ejecutar una validación simple de arranque.

## Plantilla mínima de salida esperada

- Estructura creada.
- Archivos iniciales generados.
- Comandos para empezar:
  - `build`
  - `run`
  - `test` (si aplica)

## Notas

- Priorizar MVP: solo lo necesario para iniciar.
- Mantener consistencia con reglas en `robots/rules/`.
