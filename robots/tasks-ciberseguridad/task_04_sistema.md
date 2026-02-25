# Task 04 – Scripts de auditoría del sistema

**Estado:** ⬜ pendiente  
**Depende de:** task_01  
**Bloquea:** nada

## Objetivo

Crear los scripts de hardening y auditoría del sistema local dentro de `ciberseguridad/sistema/`.

---

## Scripts a crear

### `auditar_ssh.sh`
**Descripción:** Auditoría de la configuración SSH del sistema.  
**Funcionalidad:**
- Leer `/etc/ssh/sshd_config` (requiere sudo o lectura directa)
- Evaluar y reportar:
  - `PermitRootLogin` (alertar si es `yes`)
  - `PasswordAuthentication` (alertar si está habilitado)
  - `Port` (alertar si es el 22 por defecto)
  - `AllowUsers` / `AllowGroups` (informar si no están definidos)
  - `MaxAuthTries` (alertar si > 3)
  - `Protocol` (alertar si no es 2)
  - `X11Forwarding` (informar si está activo)
- Semáforo visual por cada check: ✓ seguro / ⚠ revisar / ✗ inseguro
- Mostrar últimos 10 intentos de login fallidos (desde `journalctl` o `/var/log/auth.log`)
- Listar claves autorizadas en `~/.ssh/authorized_keys`

**Dependencias:** `sshd` (instalado), `journalctl` o `auth.log`

---

### `firewall_status.sh`
**Descripción:** Estado y resumen de reglas del firewall.  
**Funcionalidad:**
- Detectar qué firewall está activo: `ufw`, `firewalld`, o `iptables`
- Para `ufw`: mostrar estado, reglas activas
- Para `firewalld`: mostrar zona activa, servicios permitidos
- Para `iptables`: mostrar reglas INPUT, OUTPUT, FORWARD
- Detectar si el firewall está inactivo y alertar
- Mostrar puertos abiertos al exterior cruzado con reglas del firewall

**Dependencias:** `ufw` o `firewalld` o `iptables` (detectar cuál hay)

---

### `usuarios_sospechosos.sh`
**Descripción:** Revisión de usuarios del sistema en busca de anomalías.  
**Funcionalidad:**
- Listar usuarios con UID 0 (solo debería ser root)
- Listar usuarios con shell válida (no `/sbin/nologin` ni `/bin/false`)
- Mostrar usuarios con últimos logins (`lastlog`)
- Detectar usuarios con home directory en rutas inusuales
- Listar grupos privilegiados (sudo, wheel, docker, adm) y sus miembros
- Mostrar sesiones activas actuales (`who`, `w`)

**Dependencias:** `lastlog`, `who`, `w` (incluidos en sistema)

---

## Convenciones a seguir

- Cargar `common.sh`
- Verificar dependencias con `check_command`
- Advertir si se necesita `sudo` para ciertos checks y ejecutar con él si está disponible
- Funciones puras para parsear configuraciones y evaluar severidad
- Funciones de efecto para leer archivos y ejecutar comandos de sistema
- Pausa con `read` al final
- `exit 0` / código no-cero según resultado
