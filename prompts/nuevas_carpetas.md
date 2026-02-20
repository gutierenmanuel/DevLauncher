# Nuevas carpetas en scripts (categorías y subcarpetas)

Usa estas reglas cuando crees carpetas nuevas dentro de `scripts/linux` o `scripts/win`.

## 1) Dónde crear carpetas

- Linux/macOS: dentro de `scripts/linux/`.
- Windows: dentro de `scripts/win/`.
- No usar `lib` como categoría funcional (el launcher la ignora).

## 2) Cuándo una carpeta aparece en el launcher

Una carpeta se muestra solo si contiene elementos detectables por el launcher:

- scripts válidos para la plataforma (`.sh` en Linux/macOS, `.ps1`/`.bat` en Windows), o
- subcarpetas (el launcher las muestra como navegación interna).

Si está vacía, no aparece.

## 3) Metadatos por carpeta con README

Cada carpeta de categoría o subcategoría debería tener un `README.md`.

El launcher lee metadatos así:

1. Busca un archivo cuyo nombre empiece por `README` (case-insensitive).
2. Toma el primer encabezado no vacío (`# ...`).
3. Si el primer token del header es emoji/símbolo, lo usa como icono.
4. Toma la primera línea no vacía debajo del header (que no empiece por `#`) como descripción.

Si no hay metadatos válidos, usa icono/descripcion por defecto.

## 4) Formato recomendado de README

```md
# 🧪 nombre_carpeta
Descripción corta y útil de lo que contiene esta categoría.
```

Recomendaciones:

- Primera línea: header con emoji + nombre de carpeta.
- Segunda línea útil: descripción clara (1 frase).
- Evita iniciar la descripción con `#` para que sea tomada como texto.

## 5) Reglas para scripts dentro de la carpeta

- Respeta extensiones soportadas por plataforma.
- No usar prefijo `example_` en scripts finales (el launcher los ignora).
- Mantener nombres de carpeta y scripts coherentes con su función.

## 6) Subcarpetas (navegación jerárquica)

- Las subcarpetas también se muestran en el launcher.
- Pueden tener su propio `README.md` para icono y descripción.
- Úsalas para agrupar scripts por dominio sin mezclar responsabilidades.

## 7) Checklist rápido

- [ ] La carpeta está en `scripts/linux` o `scripts/win` según plataforma.
- [ ] Contiene al menos un script válido o subcarpeta.
- [ ] Tiene `README.md` con header e icono.
- [ ] Tiene descripción debajo del header.
- [ ] No usa `lib` como categoría funcional.
- [ ] No incluye scripts finales con prefijo `example_`.
