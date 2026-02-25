# Task 05 – Utilidades criptográficas

**Estado:** ⬜ pendiente  
**Depende de:** task_01  
**Bloquea:** nada

## Objetivo

Crear las utilidades criptográficas de uso cotidiano dentro de `ciberseguridad/utilidades/`.

---

## Scripts a crear

### `generar_password.sh`
**Descripción:** Generador de contraseñas seguras con múltiples modos.  
**Funcionalidad:**
- Menú de modos:
  1. Alfanumérico + símbolos (modo por defecto)
  2. Solo alfanumérico (compatible con sistemas restrictivos)
  3. Passphrase de palabras aleatorias (diceware-style, usando `/usr/share/dict/words`)
  4. PIN numérico de longitud configurable
- Pedir longitud (default: 24)
- Generar con `openssl rand` o `/dev/urandom`
- Mostrar N variantes a la vez (default: 5) para elegir
- Mostrar estimación de entropía (bits)
- No guardar en disco ni en historial

**Dependencias:** `openssl`

---

### `verificar_hash.sh`
**Descripción:** Verificación de integridad de archivos mediante hash.  
**Funcionalidad:**
- Pedir ruta de archivo
- Menú de algoritmos: MD5, SHA1, SHA256, SHA512
- Calcular y mostrar el hash del archivo
- Opción de comparar contra un hash conocido (pegar el hash esperado)
- Resultado visual: ✓ COINCIDE / ✗ NO COINCIDE
- Soporte para verificar varios archivos a la vez si se pasa un directorio

**Dependencias:** `md5sum`, `sha256sum`, `sha512sum` (incluidos en sistema)

---

### `cifrar_archivo.sh`
**Descripción:** Cifrar y descifrar archivos con AES-256 usando contraseña.  
**Funcionalidad:**
- Menú: cifrar / descifrar
- **Cifrar:**
  - Pedir archivo de entrada
  - Pedir contraseña (dos veces para confirmar, sin echo)
  - Cifrar con `openssl enc -aes-256-cbc -pbkdf2`
  - Guardar como `<archivo>.enc`
- **Descifrar:**
  - Pedir archivo `.enc`
  - Pedir contraseña
  - Descifrar y guardar como `<archivo>` (sin `.enc`)
- Mostrar tamaño del archivo resultante
- Advertir que la contraseña no se puede recuperar

**Dependencias:** `openssl`

---

## Convenciones a seguir

- Cargar `common.sh`
- Nunca escribir contraseñas o claves en disco ni en variables exportadas
- Usar `read -s` para entrada de contraseñas (sin echo)
- Funciones puras para construir comandos y validar parámetros
- Funciones de efecto para ejecutar operaciones criptográficas
- Pausa con `read` al final
- `exit 0` / código no-cero según resultado
