# Plan – scripts/linux/ciberseguridad

## Objetivo

Crear la categoría `ciberseguridad/` dentro de `scripts/linux/` con scripts orientados a análisis de red, reconocimiento, auditoría y hardening. Todos siguen las convenciones del repo (common.sh, funciones puras + middleware + orquestación, pausa al final).

## Estructura objetivo

```
scripts/linux/ciberseguridad/
  README.md
  redes/
    README.md
    escaneo_puertos.sh
    analisis_dns.sh
    conexiones_activas.sh
    geoip.sh
  web/
    README.md
    cabeceras_http.sh
    ssl_cert_info.sh
    subdominios.sh
  sistema/
    README.md
    auditar_ssh.sh
    firewall_status.sh
    usuarios_sospechosos.sh
  utilidades/
    README.md
    generar_password.sh
    verificar_hash.sh
    cifrar_archivo.sh
```

---

## Tareas en orden

| # | Archivo | Estado | Descripción |
|---|---------|--------|-------------|
| 01 | [task_01_estructura.md](task_01_estructura.md) | ✅ completado | README principal + subcarpetas con sus README |
| 02 | [task_02_redes.md](task_02_redes.md)           | ✅ completado | Scripts de análisis de red (puertos, DNS, conexiones, geoIP) |
| 03 | [task_03_web.md](task_03_web.md)               | ✅ completado | Scripts de análisis web (HTTP headers, SSL, subdominios) |
| 04 | [task_04_sistema.md](task_04_sistema.md)       | ✅ completado | Scripts de auditoría del sistema local (SSH, firewall, usuarios) |
| 05 | [task_05_utilidades.md](task_05_utilidades.md) | ✅ completado | Utilidades criptográficas (passwords, hashes, cifrado) |

---

## Dependencias de herramientas externas

Cada script debe verificar sus dependencias antes de ejecutar y guiar al usuario a instalarlas si faltan.

| Herramienta | Usada en | Instalación |
|---|---|---|
| `nmap` | escaneo_puertos | `apt install nmap` |
| `dig` / `nslookup` | analisis_dns | `apt install dnsutils` |
| `ss` / `netstat` | conexiones_activas | incluido en sistema |
| `curl` | cabeceras_http, geoip | `apt install curl` |
| `openssl` | ssl_cert_info, cifrar_archivo | `apt install openssl` |
| `whois` | analisis_dns | `apt install whois` |
| `ufw` / `iptables` | firewall_status | incluido en sistema |
| `pwgen` / `openssl` | generar_password | `apt install pwgen` |
| `sha256sum` / `md5sum` | verificar_hash | incluido en sistema |

## Estado

- ⬜ pendiente
- 🔄 en progreso
- ✅ completado
