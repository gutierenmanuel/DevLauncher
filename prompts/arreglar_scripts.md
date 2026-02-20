# Arreglar scripts

Usa este prompt cuando se corrija un script existente y quieras cerrar el bug con prevención real de regresiones.

## 1) Cuándo usarlo

Aplicar en cambios sobre scripts de:

- Linux/macOS: `.sh`
- Windows: `.ps1` y `.bat`

Especialmente cuando hubo:

- error en tiempo de ejecución,
- salida/código de error incorrecto,
- validación de entrada incompleta,
- ruptura de compatibilidad por plataforma,
- regresiones reportadas por usuarios.

## 2) Regla principal (obligatoria)

Por cada fallo corregido, **debe añadirse o actualizarse al menos un test que reproduzca ese fallo** y valide que no vuelva a ocurrir.

Sin test de regresión, la corrección se considera incompleta.

## 3) Flujo recomendado de trabajo

1. Reproducir el fallo con el caso más pequeño posible.
2. Documentar brevemente la causa raíz.
3. Corregir el script con el cambio mínimo necesario.
4. Añadir test de regresión del fallo corregido.
5. Ejecutar tests relacionados (mínimo: el nuevo test + suite cercana).
6. Verificar código de salida (`0` éxito, no-cero error) y mensajes clave.

## 4) Dónde ubicar los tests

Seguir la estructura existente del repositorio:

- Linux: usar `scripts/linux/<categoria>/tests/` y el runner de la categoría (ej. `tests_de_scripts.sh`).
- Windows: usar `scripts/win/<categoria>/tests/` y el runner de la categoría (ej. `tests_de_scripts.ps1` / `Run-Tests.ps1`).

Si la categoría no tiene tests aún:

- crear una estructura mínima de tests coherente con la categoría,
- dejar el script principal de ejecución de tests para esa categoría.

## 5) Qué debe validar el test de regresión

El test debe cubrir, como mínimo:

- **Entrada que antes fallaba** (datos reales o simulados).
- **Comportamiento esperado tras el fix**.
- **Código de salida esperado**.
- **Mensaje/resultado verificable** (stdout/stderr) cuando aplique.

Evitar tests genéricos que no reproduzcan el bug real.

## 6) Criterios de implementación del fix

- Priorizar corrección de **causa raíz**, no parche superficial.
- Mantener cambios pequeños y enfocados.
- No mezclar refactors no relacionados en el mismo arreglo.
- Mantener estilo y convenciones del repo.

## 7) Cierre de la tarea (checklist)

- [ ] El bug se reproduce antes del fix (o está documentado cómo se reproducía).
- [ ] Se aplicó fix mínimo y enfocado.
- [ ] Se añadió/actualizó test de regresión específico para ese bug.
- [ ] El nuevo test falla sin el fix y pasa con el fix.
- [ ] Se ejecutó el runner de tests de la categoría afectada.
- [ ] Se validaron códigos de salida y mensajes relevantes.
- [ ] Se actualizó documentación si el comportamiento visible cambió.

## 8) Plantilla breve para reportar el arreglo

- **Fallo corregido:** <descripción corta>
- **Causa raíz:** <1-2 líneas>
- **Fix aplicado:** <cambio principal>
- **Test de regresión:** <nombre/ruta del test>
- **Validación ejecutada:** <comando/suite>
- **Resultado:** <pasó/falló + notas>
