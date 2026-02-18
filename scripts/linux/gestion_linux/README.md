# Scripts de Gestión de Linux 🐧

Scripts interactivos para monitoreo y administración del sistema Linux.

## 📋 Scripts Disponibles

### 1. control_procesos.sh

Herramienta completa para gestionar y monitorear procesos del sistema.

**Funcionalidades:**

1. **Ver todos los procesos**
   - Lista procesos ordenados por uso de CPU
   - Muestra: Usuario, PID, %CPU, %MEM, TIME, COMMAND

2. **Buscar proceso por nombre**
   - Búsqueda case-insensitive
   - Muestra todos los procesos que coincidan

3. **Buscar proceso por puerto**
   - Encuentra qué proceso está usando un puerto específico
   - Soporta ss y netstat

4. **Ver procesos por usuario**
   - Filtra procesos de un usuario específico
   - Por defecto muestra el usuario actual

5. **Top 10 procesos (CPU)**
   - Procesos que más CPU están consumiendo
   - Actualización instantánea

6. **Top 10 procesos (Memoria)**
   - Procesos que más RAM están consumiendo
   - Muestra uso porcentual

7. **Matar proceso**
   - Terminar proceso de forma segura (SIGTERM)
   - Opción de forzar terminación (SIGKILL)
   - Confirmación antes de actuar

8. **Monitor en tiempo real**
   - Abre htop si está disponible
   - Fallback a top si htop no está instalado
   - Actualización dinámica

9. **Ver árbol de procesos**
   - Muestra jerarquía de procesos (pstree)
   - Fallback a ps auxf

**Uso:**

```bash
# Desde el lanzador
dl
# → gestion_linux → control_procesos.sh

# O directamente
./scripts/linux/gestion_linux/control_procesos.sh
```

**Casos de uso comunes:**

```bash
# Encontrar y matar proceso que usa puerto 8080
1. Seleccionar opción 3
2. Introducir puerto: 8080
3. Anotar el PID
4. Seleccionar opción 7
5. Introducir el PID

# Ver qué proceso consume más CPU
1. Seleccionar opción 5

# Monitorear procesos de un usuario
1. Seleccionar opción 4
2. Introducir nombre de usuario
```

---

### 2. puertos_activos.sh

Monitor completo de puertos de red y conexiones.

**Funcionalidades:**

1. **Ver todos los puertos abiertos (LISTEN)**
   - Muestra todos los puertos en escucha
   - TCP y UDP juntos
   - Incluye proceso que los usa

2. **Ver puertos TCP**
   - Solo puertos TCP
   - Estado LISTEN

3. **Ver puertos UDP**
   - Solo puertos UDP
   - Incluye información del proceso

4. **Buscar proceso por puerto específico**
   - Busca en TCP y UDP
   - Muestra información detallada del proceso

5. **Ver conexiones establecidas**
   - Solo conexiones activas (ESTABLISHED)
   - Muestra IP remota y puerto
   - Cuenta total de conexiones

6. **Ver puertos por proceso**
   - Busca por nombre de proceso
   - Lista todos los puertos que usa

7. **Ver estadísticas de red**
   - Resumen de conexiones (ss -s)
   - Interfaces de red activas
   - Estadísticas generales

8. **Escanear puerto específico**
   - Verifica si un puerto está abierto
   - Soporta host remoto o localhost
   - Usa nc, telnet o bash built-in

**Uso:**

```bash
# Desde el lanzador
dl
# → gestion_linux → puertos_activos.sh

# O directamente
./scripts/linux/gestion_linux/puertos_activos.sh
```

**Casos de uso comunes:**

```bash
# Ver qué proceso usa el puerto 3000
1. Seleccionar opción 4
2. Introducir: 3000

# Ver todas las conexiones establecidas
1. Seleccionar opción 5

# Verificar si puerto 8080 está abierto
1. Seleccionar opción 8
2. Puerto: 8080
3. Host: localhost
```

**Herramientas soportadas:**
- **ss** (Socket Statistics) - Preferido
- **netstat** - Fallback
- **nc** (netcat) - Para escaneo
- **telnet** - Fallback para escaneo

---

### 3. espacio_disponible.sh

Análisis completo de uso de disco y almacenamiento.

**Funcionalidades:**

1. **Ver espacio en discos/particiones**
   - Muestra todos los sistemas de archivos
   - Formato humano (GB, MB)
   - Alerta si uso >90%
   - Excluye tmpfs y loops

2. **Top 10 carpetas más grandes**
   - En el directorio actual
   - Ordenadas por tamaño
   - Análisis profundidad 1

3. **Top 20 archivos más grandes**
   - En el directorio actual
   - Búsqueda recursiva
   - Ordenados por tamaño

4. **Analizar carpeta específica**
   - Tamaño total
   - Número de archivos y carpetas
   - Top 5 subcarpetas

5. **Buscar archivos grandes**
   - Tamaño mínimo configurable (default 100MB)
   - Directorio de búsqueda configurable
   - Top 30 resultados

6. **Espacio usado por tipo de archivo**
   - Agrupa por extensión
   - Muestra tamaño total por tipo
   - Top 10 extensiones

7. **Análisis del home (~)**
   - Tamaño total del home
   - Top 10 carpetas
   - Carpetas de caché comunes:
     - ~/.cache
     - ~/.local
     - ~/.npm
     - ~/.cargo
     - ~/.vscode

8. **Limpiar cache del sistema**
   - Requiere sudo
   - Limpia apt cache
   - Limpia journalctl (logs >7 días)
   - Limpia caché de usuario
   - Limpia thumbnails
   - Muestra espacio liberado

9. **Ver inodos disponibles**
   - Muestra uso de inodos
   - Alerta si >90%
   - Útil para servidores con muchos archivos pequeños

**Uso:**

```bash
# Desde el lanzador
dl
# → gestion_linux → espacio_disponible.sh

# O directamente
./scripts/linux/gestion_linux/espacio_disponible.sh
```

**Casos de uso comunes:**

```bash
# Liberar espacio rápidamente
1. Seleccionar opción 8 (Limpiar cache)
2. Confirmar con 's'

# Encontrar qué ocupa espacio en home
1. Seleccionar opción 7 (Análisis del home)

# Buscar archivos grandes para eliminar
1. Seleccionar opción 5
2. Tamaño: 500 (buscar >500MB)
3. Directorio: /home/usuario

# Ver qué carpeta consume más en un proyecto
1. cd ~/proyectos/mi-proyecto
2. ./espacio_disponible.sh
3. Opción 2 (Top carpetas)
```

---

## 🚀 Flujo de Trabajo Típico

### Problema: Servidor lento

```bash
# 1. Ver uso de CPU y memoria
dl → gestion_linux → control_procesos.sh
→ Opción 5 (Top CPU)
→ Opción 6 (Top Memoria)

# 2. Verificar conexiones de red
dl → gestion_linux → puertos_activos.sh
→ Opción 5 (Conexiones establecidas)

# 3. Verificar espacio en disco
dl → gestion_linux → espacio_disponible.sh
→ Opción 1 (Espacio en discos)
```

### Problema: Puerto ocupado

```bash
# 1. Buscar qué proceso usa el puerto
dl → gestion_linux → puertos_activos.sh
→ Opción 4 (Buscar por puerto)
→ Introducir: 8080

# 2. Terminar el proceso si es necesario
dl → gestion_linux → control_procesos.sh
→ Opción 7 (Matar proceso)
→ Introducir PID del paso anterior
```

### Problema: Disco lleno

```bash
# 1. Ver qué disco está lleno
dl → gestion_linux → espacio_disponible.sh
→ Opción 1 (Espacio en discos)

# 2. Analizar carpetas grandes
→ Opción 2 (Top carpetas)

# 3. Buscar archivos grandes
→ Opción 5 (Archivos >100MB)

# 4. Limpiar cache
→ Opción 8 (Limpiar cache)
```

---

## 📊 Tabla Resumen

| Script | Funciones | Propósito Principal |
|--------|-----------|---------------------|
| **control_procesos.sh** | 9 | Gestionar procesos del sistema |
| **puertos_activos.sh** | 8 | Monitorear red y puertos |
| **espacio_disponible.sh** | 9 | Analizar uso de disco |

---

## 💡 Tips y Trucos

### Control de Procesos

**Matar proceso zombie:**
```bash
# Buscar procesos zombie
ps aux | grep 'Z'

# Usar el script para matarlos
# Opción 7 → Introducir PID padre
```

**Monitorear proceso específico:**
```bash
# Opción 8 (Monitor en tiempo real)
# En htop: F4 para filtrar
```

### Puertos Activos

**Ver qué servicio usa un puerto estándar:**
```bash
# Opción 4 → Puerto 80 (HTTP)
# Opción 4 → Puerto 443 (HTTPS)
# Opción 4 → Puerto 22 (SSH)
# Opción 4 → Puerto 3306 (MySQL)
```

**Verificar si servidor web está corriendo:**
```bash
# Opción 8 (Escanear puerto)
# Puerto: 80 o 443
# Host: localhost
```

### Espacio Disponible

**Encontrar logs grandes:**
```bash
# Opción 4 (Analizar carpeta)
# Ruta: /var/log
```

**Limpiar node_modules viejos:**
```bash
# Opción 5 (Archivos grandes)
# En directorio de proyectos
# Buscar: node_modules
```

**Ver qué tipo de archivos ocupan más:**
```bash
# Opción 6 (Por tipo de archivo)
# Útil para ver si videos, logs, etc. ocupan mucho
```

---

## 🛠️ Requisitos

### Herramientas Necesarias

**Control de Procesos:**
- ✅ `ps` (incluido en coreutils)
- ✅ `grep` (incluido en coreutils)
- ⚠️ `htop` (opcional, recomendado)
- ⚠️ `pstree` (opcional, recomendado)

**Puertos Activos:**
- ✅ `ss` (incluido en iproute2) - Preferido
- ⚠️ `netstat` (fallback, net-tools)
- ⚠️ `nc` (netcat, opcional)
- ⚠️ `telnet` (opcional)

**Espacio Disponible:**
- ✅ `df` (incluido en coreutils)
- ✅ `du` (incluido en coreutils)
- ✅ `find` (incluido en findutils)

### Instalar herramientas opcionales

```bash
# Ubuntu/Debian
sudo apt install htop pstree net-tools netcat

# Fedora
sudo dnf install htop psmisc net-tools nmap-ncat

# Arch
sudo pacman -S htop psmisc net-tools gnu-netcat
```

---

## 🔒 Permisos

### Operaciones sin sudo
- ✅ Ver procesos del usuario actual
- ✅ Ver puertos >1024 abiertos por el usuario
- ✅ Analizar carpetas propias
- ✅ Limpiar cache del usuario (~/.cache)

### Operaciones con sudo
- ⚠️ Ver todos los procesos del sistema
- ⚠️ Matar procesos de otros usuarios
- ⚠️ Ver puertos <1024 y sus procesos
- ⚠️ Limpiar cache del sistema (apt, journalctl)

---

## 🐛 Troubleshooting

### "command not found: ss"

Instala iproute2 o usa netstat:
```bash
sudo apt install iproute2
```

### "Permission denied" al ver puertos

Usa sudo o limítate a puertos >1024:
```bash
sudo ./puertos_activos.sh
```

### "Permission denied" al matar proceso

Solo puedes matar tus propios procesos, usa sudo:
```bash
# Ver PID con sudo primero
sudo ./control_procesos.sh
```

### Análisis de disco muy lento

Limita el análisis a carpetas específicas:
```bash
# En lugar de analizar todo /
# Analiza carpetas específicas: /home, /var, etc.
```

---

## 📚 Recursos

- [ps - Manual](https://man7.org/linux/man-pages/man1/ps.1.html)
- [ss - Manual](https://man7.org/linux/man-pages/man8/ss.8.html)
- [du - Manual](https://man7.org/linux/man-pages/man1/du.1.html)
- [Linux Performance Tools](https://www.brendangregg.com/linuxperf.html)
