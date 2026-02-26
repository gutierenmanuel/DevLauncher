# Nuevos scripts en DevLauncher

Estas reglas están alineadas con cómo funciona actualmente el launcher y los scripts del repo.

## 1) Dónde crear el script

- Linux/macOS: `scripts/linux/<categoria>/mi_script.sh`
- Windows: `scripts/win/<categoria>/mi_script.ps1` (o `.bat` si aplica)
- No poner scripts ejecutables dentro de `lib/` (el launcher lo ignora).
- No usar prefijo `example_` en scripts finales (el launcher los ignora).

## 2) Extensiones soportadas por el launcher

- En Windows: `.ps1` y `.bat`
- En Linux/macOS: `.sh`

Si usas otra extensión, no aparecerá en el launcher.

## 3) Cómo mostrar nombre y descripción en el launcher

El launcher extrae la descripción de las primeras líneas del script:

- Revisa hasta las primeras 5 líneas.
- Ignora shebang y líneas vacías.
- Toma el primer comentario útil (`# ...`).

Convención recomendada (primera o segunda línea):

```bash
#!/bin/bash
# Script: Descripción clara y corta
```

```powershell
# Script: Descripción clara y corta
```

## 4) Comunicación correcta con el launcher (éxito/error)

El launcher:

- Muestra `stdout` del script en tiempo real.
- Interpreta éxito/error por código de salida.
- En fallos, muestra el código de salida y el error.

Reglas:

- Sal éxito con `exit 0`.
- En error, usa código no-cero (`exit 1`, `exit 2`, etc.).
- Escribe errores a `stderr` cuando tenga sentido.
- No ocultes errores críticos.

## 5) Pausa obligatoria para scripts "rápidos"

Si el script imprime info corta (ej: versión, chequeos, abrir carpeta), debe pausar al final para que se pueda leer.

### Bash

```bash
pause_and_exit() {
	local code="${1:-0}"
	read -r -p "Pulsa Enter para continuar"
	exit "$code"
}

# ... lógica
pause_and_exit 0
```

### PowerShell

```powershell
function Pause-And-Exit([int]$Code = 0) {
		Read-Host "Pulsa Enter para continuar"
		exit $Code
}

# ... lógica
Pause-And-Exit 0
```

También usar pausa en salidas por error cuando el script sea de consulta/lectura rápida.

## 6) Cuándo usar selección numérica

Usa selección numérica cuando haya varias acciones posibles en un mismo script (submenús de gestión, utilidades, etc.).

Buenas prácticas:

- Mostrar opciones numeradas claras (`1..N` + `0 Salir`).
- Validar entrada vacía o inválida.
- Mantener bucle hasta salir.
- Tras ejecutar una opción, mostrar pausa (`Enter`) antes de redibujar menú.

### Patrón Bash

```bash
while true; do
	echo "1) Opción A"
	echo "2) Opción B"
	echo "0) Salir"
	read -r -p "Selecciona una opción: " option
	case "$option" in
		1) echo "Ejecutando A..." ;;
		2) echo "Ejecutando B..." ;;
		0) break ;;
		*) echo "Opción inválida" ;;
	esac
	read -r -p "Presiona Enter para continuar..."
done
```

### Patrón PowerShell

```powershell
while ($true) {
		Write-Host "1) Opción A"
		Write-Host "2) Opción B"
		Write-Host "0) Salir"
		$option = Read-Host "Selecciona una opción"

		switch ($option) {
				"1" { Write-Host "Ejecutando A..." }
				"2" { Write-Host "Ejecutando B..." }
				"0" { break }
				default { Write-Host "Opción inválida" }
		}

		Read-Host "Presiona Enter para continuar..." | Out-Null
}
```

## 7) Integración por carpeta (icono + descripción)

Cada carpeta de scripts puede tener `README.md` para metadatos de categoría.

El launcher usa:

- Primer encabezado markdown (`# ...`) como referencia.
- Si el primer token del header es emoji, lo usa como icono.
- Primera línea no vacía debajo del header (que no sea otro `#`) como descripción.

Ejemplo recomendado:

```md
# 🧪 configuracion_devlauncher
Scripts de mantenimiento de instalación y estado de DevLauncher.
```

## 8) Estilo y robustez mínima

- Mantener mensajes en español, claros y accionables.
- Usar confirmación para acciones destructivas (`(s/N)`).
- En Linux, usar `set -e` (y opcionalmente `set -u -o pipefail`).
- En scripts Linux de desarrollo, reutilizar `scripts/lib/common.sh` cuando aplique.
- Evitar rutas hardcodeadas; usar rutas relativas o `$HOME`.

## 9) Checklist rápido antes de guardar

- [ ] Está en carpeta correcta (`scripts/linux` o `scripts/win`).
- [ ] Extensión soportada por plataforma.
- [ ] Tiene comentario descriptivo al inicio.
- [ ] Si es script rápido, tiene pausa final.
- [ ] Si tiene múltiples acciones, usa menú numérico validado.
- [ ] Devuelve código de salida correcto (`0` éxito / no-cero error).
- [ ] Si es nueva categoría/subcarpeta, tiene `README.md` con icono+descripción.

## 10) Compatibilidad con LLM (recomendado)

Para que un LLM seleccione y ejecute scripts con menor error:

- Usa nombres únicos y expresivos (evitar duplicados como `run.ps1` en varias carpetas).
- Incluye una descripción inicial concreta con verbo + objetivo.
- Documenta parámetros esperados al inicio del script (comentario breve de uso).
- Evita prompts interactivos innecesarios cuando el script reciba parámetros por CLI.
- Mantén salida legible y estable para parseo automático (mensajes consistentes).
