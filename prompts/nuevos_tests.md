# Nuevos tests en DevLauncher

Usa este prompt cuando crees o actualices tests para scripts del proyecto.

## 1) Objetivo

Definir reglas únicas para que los tests sean consistentes, seguros y sin efectos colaterales.

## 2) Cuándo usarlo

Aplicar siempre que:

- se agregue un test nuevo,
- se modifique un test existente,
- se corrija un bug y se deba cubrir con test de regresión.

## 3) Regla principal de ubicación (obligatoria)

Todos los tests deben vivir en:

- `scripts/win/configuracion_devlauncher/tests/`
- `scripts/linux/configuracion_devlauncher/tests/`

No crear tests en otras carpetas de `scripts/win/*/tests` ni `scripts/linux/*/tests`.

## 4) Regla principal de comportamiento (obligatoria)

Cada test debe comprobar que el script **funciona de verdad** y, cuando haya acciones con efecto real, se debe usar mock.

Esto incluye (según corresponda):

- procesos del sistema,
- red,
- puertos,
- archivos/carpetas del usuario,
- instalación/desinstalación,
- cambios de configuración global.

Si el script necesita ejecutar algo externo, mockear esa llamada y verificar:

1. que la llamada se realiza,
2. con los parámetros esperados,
3. en el flujo esperado (caso éxito/error),
4. sin modificar el sistema real.

## 5) Qué validar en cada test

Como mínimo:

- salida o resultado esperado,
- código de salida esperado (`0` éxito, no-cero error),
- rama importante de error cuando aplique,
- verificación de mocks (`Should -Invoke`, conteo, parámetros),
- ausencia de efectos reales durante la prueba.

## 6) Flujo recomendado

1. Definir caso real de uso (y bug si aplica).
2. Preparar dobles/mocks para toda operación con side effects.
3. Ejecutar script o función bajo prueba.
4. Verificar resultado funcional y llamadas mockeadas.
5. Ejecutar runner de tests y confirmar que pasa.

## 7) Criterios de calidad

- Tests pequeños, legibles y deterministas.
- Sin dependencia de internet, permisos admin o estado local del equipo.
- Evitar sleeps/retries innecesarios.
- Nombrar tests con intención clara del comportamiento validado.

## 8) Checklist final

- [ ] El test está en `scripts/win/configuracion_devlauncher/tests/` o `scripts/linux/configuracion_devlauncher/tests/`.
- [ ] Se valida funcionamiento real del script/caso.
- [ ] Toda operación con side effects está mockeada.
- [ ] Se verifican llamadas mockeadas y parámetros.
- [ ] Se valida resultado y código de salida esperado.
- [ ] El test corre en local sin afectar el sistema.
