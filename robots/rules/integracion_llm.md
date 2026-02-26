# Integración de DevLauncher con LLMs

Usa este prompt cuando el objetivo sea que un agente LLM pueda **descubrir opciones de menú, decidir una acción y ejecutar scripts** de forma no interactiva y reproducible.

## 1) Objetivo

Establecer un contrato estable para agentes:

1. Obtener árbol de menús con descripciones.
2. Elegir categoría/script con criterio explícito.
3. Ejecutar script por nombre o ruta relativa.
4. Reportar resultado estructurado (`exitCode`, `output`, ruta real ejecutada).

## 2) Contrato CLI (obligatorio)

### Descubrimiento de menús

```bash
devlauncher --menu-json
```

Salida esperada (JSON):

- `categories[]` con `name`, `description`, `icon`, `options[]`.
- Cada `option` incluye `type` (`directory` o `script`), `name`, `description`, `relPath`.
- Estructura recursiva para submenús (`options` dentro de directorios).

### Ejecución no interactiva

```bash
devlauncher --run <script|relPath|absPath> [--cwd <ruta>] [--json] [-- arg1 arg2 ...]
```

Reglas:

- Usar `--json` para respuestas consumibles por agentes.
- Preferir `relPath` completo cuando el nombre sea ambiguo.
- Si el script recibe argumentos, pasarlos después de `--`.

## 3) Protocolo recomendado para agentes

1. Llamar `--menu-json`.
2. Filtrar opciones por intención del usuario usando `name` y `description`.
3. Si hay más de un candidato, pedir desambiguación o usar `relPath` exacto.
4. Ejecutar con `--run ... --json`.
5. Reportar:
   - script ejecutado,
   - working directory,
   - exit code,
   - resumen de output,
   - siguiente acción sugerida.

## 4) Convenciones para scripts nuevos (LLM-friendly)

Para mejorar selección automática:

- Mantener descripciones claras en cabecera del script (primera línea útil comentada).
- Evitar nombres demasiado genéricos (ej. `run.ps1`, `test.sh`) sin prefijo de dominio.
- Si un script es destructivo, exigir confirmación explícita.
- Devolver códigos de salida consistentes (`0` éxito, no-cero error).

## 5) Prompt base sugerido para pedir ejecución a un LLM

Plantilla:

```text
Usa DevLauncher en modo no interactivo.
1) Ejecuta `devlauncher --menu-json`.
2) Elige el script más adecuado para: <objetivo>.
3) Si hay ambigüedad, deténte y pide confirmación mostrando candidatos.
4) Ejecuta con `devlauncher --run <relPath> --json`.
5) Devuélveme: script elegido, motivo, exitCode y resumen de output.
```

## 6) Criterios de aceptación

- [ ] El agente no depende de la TUI para navegar.
- [ ] Menús y descripciones se obtienen desde JSON.
- [ ] La ejecución devuelve trazabilidad completa.
- [ ] Ambigüedades de nombre se resuelven antes de ejecutar.
