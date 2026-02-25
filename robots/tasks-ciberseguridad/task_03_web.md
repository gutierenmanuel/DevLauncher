# Task 03 – Scripts de análisis web

**Estado:** ⬜ pendiente  
**Depende de:** task_01  
**Bloquea:** nada

## Objetivo

Crear los scripts de reconocimiento y auditoría web dentro de `ciberseguridad/web/`.

---

## Scripts a crear

### `cabeceras_http.sh`
**Descripción:** Análisis de cabeceras HTTP de seguridad de un sitio web.  
**Funcionalidad:**
- Pedir URL
- Obtener cabeceras con `curl -I`
- Evaluar presencia/ausencia de cabeceras de seguridad:
  - `Strict-Transport-Security` (HSTS)
  - `Content-Security-Policy` (CSP)
  - `X-Frame-Options`
  - `X-Content-Type-Options`
  - `Referrer-Policy`
  - `Permissions-Policy`
- Mostrar semáforo: ✓ presente / ✗ ausente / ⚠ inseguro
- Mostrar el valor de cada cabecera

**Dependencias:** `curl`

---

### `ssl_cert_info.sh`
**Descripción:** Inspector de certificados SSL/TLS de un dominio.  
**Funcionalidad:**
- Pedir dominio (con o sin puerto)
- Obtener certificado con `openssl s_client`
- Mostrar: emisor, sujeto, SANs, fechas de validez, días restantes
- Alertar si el certificado expira en menos de 30 días
- Mostrar cadena de confianza
- Verificar si el protocolo es TLS 1.2+ (alertar si acepta TLS 1.0/1.1)

**Dependencias:** `openssl`

---

### `subdominios.sh`
**Descripción:** Enumeración básica de subdominios de un dominio objetivo.  
**Funcionalidad:**
- Pedir dominio base
- Dos modos:
  1. **Diccionario**: probar lista de subdominios comunes (www, mail, ftp, api, dev, admin, vpn, etc., incluida en el script)
  2. **DNS brute** ligero: usar `dig` para resolver cada candidato
- Mostrar solo los que resuelven (tienen A/CNAME)
- Mostrar la IP que resuelve cada subdominio encontrado
- Guardar resultado en `/tmp/subdominios_<dominio>_<fecha>.txt`

**Dependencias:** `dig`, `curl`

---

## Convenciones a seguir

- Cargar `common.sh`
- Verificar dependencias con `check_command`
- Funciones puras para construir comandos y evaluar resultados
- Funciones de efecto para ejecutar peticiones y mostrar output
- Pausa con `read` al final
- `exit 0` / código no-cero según resultado
