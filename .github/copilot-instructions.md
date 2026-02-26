# Copilot Instructions (DevLauncher)

## Sobre el proyecto

**DevLauncher** es una consola interactiva TUI (Terminal User Interface) diseñada para lanzar comandos y scripts propios desde cualquier parte del sistema operativo. El objetivo principal es centralizar y organizar herramientas personalizadas (scripts de shell, comandos, utilidades) en un único punto de acceso interactivo, eliminando la necesidad de recordar rutas o escribir comandos largos manualmente.

El proyecto está compuesto por dos binarios principales:
- **launcher-go**: la interfaz TUI interactiva con la que el usuario navega y ejecuta comandos.
- **installer-go**: el instalador/desinstalador que configura DevLauncher en el sistema del usuario.

Ambos están escritos en **Go** y apuntan a ser multiplataforma (Linux, macOS, Windows).

---

## Plan de refactorización: Programación Funcional

Todo el código Go de `installer-go/` y `launcher-go/` será refactorizado aplicando principios de **programación funcional**. El objetivo es mejorar la testabilidad, la composabilidad y la claridad del flujo de datos.

### Estructura de carpetas objetivo (por módulo)

```
installer-go/
  core/        → Funciones puras: transformaciones, validaciones, parseo, lógica sin efectos secundarios
  middleware/  → Funciones impuras: I/O, sistema de archivos, red, interacción con el SO
  app/         → Orquestación: compone core y middleware en flujos de alto nivel (entry points)

launcher-go/
  core/        → Funciones puras: construcción de modelos, filtrado, ordenamiento, lógica de negocio
  middleware/  → Funciones impuras: lectura de archivos de configuración, ejecución de comandos, logging
  app/         → Orquestación: inicialización del TUI, enrutamiento de eventos, composición de capas
```

### Reglas de la refactorización

- **`core/`**: solo funciones puras. Sin efectos secundarios, sin I/O, sin estado global. Deben ser 100% testeables sin mocks.
- **`middleware/`**: funciones que interactúan con el mundo exterior (archivos, sistema operativo, red, procesos). Deben recibir dependencias como parámetros (inyección explícita) en lugar de usar globales.
- **`app/`**: punto de entrada de cada módulo. No contiene lógica de negocio propia; únicamente compone y conecta `core` y `middleware`.
- Preferir **funciones sobre métodos** cuando no haya estado mutable.
- Preferir **valores de retorno explícitos** (`value, error`) sobre panics o efectos implícitos.
- Evitar estado global; pasar configuración como parámetros o estructuras de contexto.

---

## Uso obligatorio del índice de prompts

- Antes de responder tareas no triviales, consulta `robots/prompts/index.md`.
- Selecciona el prompt más adecuado según el tipo de tarea (scripts, docs, build, UX, etc.).
- Si existe un prompt específico para la tarea, úsalo como guía principal.
- Si no existe, aplica las reglas generales del repositorio y propone crear un nuevo prompt en `robots/prompts/`.

## Flujo recomendado para cada solicitud

1. Clasificar la tarea (implementación, documentación, validación, refactor, etc.).
2. Revisar `robots/prompts/index.md` y elegir el prompt aplicable.
3. Ejecutar la tarea alineado a ese prompt y al estilo del repo.
4. Validar cambios (build/tests cuando aplique).
5. Reportar qué se cambió y qué prompt del índice se usó.

## Verificación previa ante dudas

- Si falta información, hay ambigüedad o no se conoce un detalle clave, preguntar al usuario antes de ejecutar cambios.
- No asumir requisitos críticos sin confirmación explícita.
- Hacer 1 a 3 preguntas concretas para validar alcance, contexto o criterio de aceptación cuando sea necesario.
- Reanudar la ejecución solo después de tener claridad suficiente para actuar con seguridad.

## Convenciones de mantenimiento del índice

- Cada nuevo archivo en `robots/prompts/*.md` debe añadirse en `robots/prompts/index.md`.
- Mantener descripciones cortas y orientadas a cuándo usar cada prompt.
- Evitar duplicar prompts con objetivos idénticos.

## Prioridad de instrucciones

1. Solicitud del usuario.
2. `robots/prompts/index.md` + prompt específico seleccionado.
3. Estas instrucciones de `copilot-instructions.md`.
4. Convenciones existentes del código/documentación.
