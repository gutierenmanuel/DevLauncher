# Task 02 – Scripts de redes

**Estado:** ⬜ pendiente  
**Depende de:** task_01  
**Bloquea:** nada

## Objetivo

Crear los scripts de análisis y reconocimiento de red dentro de `ciberseguridad/redes/`.

---

## Scripts a crear

### `escaneo_puertos.sh`
**Descripción:** Escáner de puertos interactivo usando `nmap`.  
**Funcionalidad:**
- Pedir IP o rango objetivo
- Menú: escaneo rápido / completo / servicios y versiones / OS detection
- Mostrar resultados con tabla coloreada
- Guardar resultado en `/tmp/scan_<fecha>.txt` (opcional)

**Dependencias:** `nmap`

---

### `analisis_dns.sh`
**Descripción:** Análisis DNS completo de un dominio.  
**Funcionalidad:**
- Pedir dominio
- Consultar: A, AAAA, MX, NS, TXT, CNAME, SOA
- Mostrar registros agrupados por tipo
- Opción de whois del dominio
- Opción de comprobar si el dominio está en listas negras (DNSBL básico)

**Dependencias:** `dig`, `whois`, `curl`

---

### `conexiones_activas.sh`
**Descripción:** Monitor de conexiones de red activas y puertos en escucha.  
**Funcionalidad:**
- Ver todas las conexiones establecidas
- Ver solo puertos en escucha con el proceso asociado
- Filtrar por puerto o proceso
- Detectar conexiones externas (IPs no locales)
- Refrescar en tiempo real (loop opcional)

**Dependencias:** `ss`, `lsof` (opcional)

---

### `geoip.sh`
**Descripción:** Geolocalización de una IP o dominio.  
**Funcionalidad:**
- Pedir IP o dominio
- Consultar API pública (ip-api.com o similar, sin key)
- Mostrar: país, ciudad, ISP, ASN, latitud/longitud
- Detectar si es VPN/Proxy/Tor (si la API lo informa)
- Opción de consultar la IP pública propia

**Dependencias:** `curl`, `dig` (para resolver dominio)

---

## Convenciones a seguir

- Cargar `common.sh`
- Verificar cada dependencia con `check_command` antes de usarla
- Funciones puras para construir comandos y parsear salidas
- Funciones de efecto para ejecutar y mostrar
- Pausa con `read` al final de cada acción
- `exit 0` en salida normal, código no-cero en error
