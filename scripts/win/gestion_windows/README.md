# 🪟 Scripts de Gestión de Windows

Scripts interactivos para monitoreo y administración del sistema Windows, equivalentes a los de `gestion_linux` pero usando PowerShell nativo.

## 📋 Scripts Disponibles

### 1. control_procesos.ps1

Herramienta completa para gestionar y monitorear procesos del sistema.

**Funcionalidades:**

1. **Ver todos los procesos** — Top 30 ordenados por CPU
2. **Buscar proceso por nombre** — Búsqueda con wildcard, case-insensitive
3. **Buscar proceso por puerto** — Encuentra el proceso que usa un puerto TCP/UDP
4. **Top 10 procesos (CPU)** — Los que más CPU consumen
5. **Top 10 procesos (Memoria)** — Los que más RAM consumen
6. **Terminar proceso** — Termina por PID (con confirmación y opción de forzar)
7. **Ver árbol de procesos** — Jerarquía padre/hijo con `Win32_Process`
8. **Ver procesos que no responden** — Detecta procesos "colgados"

**Equivalencias Linux:**

| Linux (`ps`, `kill`, `htop`) | Windows (PowerShell) |
|------------------------------|----------------------|
| `ps aux`                     | `Get-Process`        |
| `kill <pid>`                 | `Stop-Process -Id`   |
| `kill -9 <pid>`              | `Stop-Process -Force`|
| `pstree`                     | `Win32_Process`      |

---

### 2. puertos_activos.ps1

Monitor completo de puertos de red y conexiones.

**Funcionalidades:**

1. **Ver todos los puertos abiertos (Listening)** — TCP y UDP
2. **Ver puertos TCP** — Todas las conexiones TCP con estado
3. **Ver puertos UDP** — Todos los endpoints UDP
4. **Buscar proceso por puerto** — TCP y UDP en una sola búsqueda
5. **Ver conexiones establecidas** — Solo conexiones activas (ESTABLISHED)
6. **Ver puertos por proceso** — Busca por nombre de proceso
7. **Ver estadísticas de red** — Resumen de estados, adaptadores, IPs
8. **Escanear puerto específico** — Verifica si un puerto está abierto en un host

**Equivalencias Linux:**

| Linux (`ss`, `netstat`)        | Windows (PowerShell)             |
|--------------------------------|----------------------------------|
| `ss -tulnp`                    | `Get-NetTCPConnection`           |
| `ss -unlp`                     | `Get-NetUDPEndpoint`             |
| `nc -zv host port`             | `Test-NetConnection -Port`       |
| `ip -br addr`                  | `Get-NetIPAddress`               |

---

### 3. espacio_disponible.ps1

Análisis completo de uso de disco y almacenamiento.

**Funcionalidades:**

1. **Ver espacio en unidades** — Con barra de progreso visual y alertas >90%
2. **Top 10 carpetas más grandes** — En el directorio actual
3. **Top 20 archivos más grandes** — Búsqueda recursiva en directorio actual
4. **Analizar carpeta específica** — Tamaño total, archivos, carpetas, top 5 subs
5. **Buscar archivos grandes** — Tamaño mínimo configurable (default 100 MB)
6. **Espacio por tipo de archivo** — Agrupa por extensión, top 10
7. **Análisis del directorio de usuario** — Con caché de npm, pip, .nuget, .cargo, Temp
8. **Limpiar archivos temporales** — `%TEMP%`, `LocalAppData\Temp`, `C:\Windows\Temp`

**Equivalencias Linux:**

| Linux (`df`, `du`, `find`)        | Windows (PowerShell)                   |
|-----------------------------------|----------------------------------------|
| `df -h`                           | `Get-CimInstance Win32_LogicalDisk`    |
| `du -sh */`                       | `Get-ChildItem + Measure-Object`       |
| `find . -size +100M`              | `Get-ChildItem -Recurse + Where-Object`|
| `apt-get clean`                   | `Remove-Item $env:TEMP`                |

---

### 4. visualizador_sistema.ps1

Información del sistema al estilo neofetch, sin dependencias externas.

**Funcionalidades:**

1. **Info del sistema (estilo neofetch)** — OS, CPU, RAM, GPU, discos en formato compacto
2. **Información completa** — Sección por sección: OS, CPU, RAM, GPU, discos, red
3. **Solo hardware** — CPU (núcleos, GHz), módulos RAM con slot y velocidad, GPU, discos físicos, monitores
4. **Herramientas de desarrollo** — Detecta Node, npm, pnpm, Python, pip, Git, Go, Rust, Docker, kubectl, dotnet, PowerShell
5. **Información de red** — Adaptadores activos, IPv4, IPv6, MAC, velocidad, DNS

**Equivalencias Linux:**

| Linux                        | Windows (PowerShell)                  |
|------------------------------|---------------------------------------|
| `neofetch`                   | `Show-SystemInfo` (función interna)   |
| `lscpu`                      | `Get-CimInstance Win32_Processor`     |
| `free -h`                    | `Win32_OperatingSystem` (mem fields)  |
| `lsblk`                      | `Get-CimInstance Win32_DiskDrive`     |
| `ip addr`                    | `Get-NetIPAddress`                    |

---

## 🚀 Uso

```powershell
# Desde el launcher
dl
# → gestion_windows → control_procesos.ps1

# O directamente desde PowerShell
.\scripts\win\gestion_windows\control_procesos.ps1
.\scripts\win\gestion_windows\puertos_activos.ps1
.\scripts\win\gestion_windows\espacio_disponible.ps1
.\scripts\win\gestion_windows\visualizador_sistema.ps1
```

## 🔧 Requisitos

- **PowerShell 5.1+** (incluido en Windows 10/11)
- **PowerShell 7+** recomendado para colores ANSI correctos
- Sin dependencias externas — todo usa cmdlets nativos de Windows

## 🛠️ Módulos de PowerShell utilizados

| Módulo           | Cmdlets usados                                    |
|------------------|---------------------------------------------------|
| NetTCPIP         | `Get-NetTCPConnection`, `Get-NetUDPEndpoint`      |
| NetAdapter       | `Get-NetAdapter`, `Get-NetIPAddress`              |
| CimCmdlets       | `Get-CimInstance Win32_*`                         |
| Microsoft.PowerShell.Management | `Get-Process`, `Stop-Process`, `Get-ChildItem` |
| NetConnection    | `Test-NetConnection`                              |
| DnsClient        | `Get-DnsClientServerAddress`                      |
