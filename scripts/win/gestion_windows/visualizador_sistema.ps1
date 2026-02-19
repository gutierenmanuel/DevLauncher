# Script de visualización del sistema Windows
# Muestra información del sistema al estilo neofetch

$Green  = "`e[32m"
$Yellow = "`e[33m"
$Purple = "`e[35m"
$Cyan   = "`e[36m"
$Gray   = "`e[90m"
$Red    = "`e[31m"
$Bold   = "`e[1m"
$NC     = "`e[0m"

function Show-Header {
    param($Title, $Subtitle)
    Clear-Host
    Write-Host ""
    Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
    Write-Host "${Purple}║  $Title${NC}"
    Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
    Write-Host "${Gray}  $Subtitle${NC}"
    Write-Host ""
}

function Write-Progress-Msg { param($Msg); Write-Host "  ${Cyan}⏳${NC} $Msg" }
function Write-Success      { param($Msg); Write-Host "  ${Green}✓${NC} $Msg" }
function Write-Info         { param($Msg); Write-Host "  ${Cyan}ℹ${NC} $Msg" }

function Format-Size($bytes) {
    if (-not $bytes) { return "0 B" }
    if ($bytes -ge 1GB) { return "$([math]::Round($bytes/1GB, 2)) GB" }
    if ($bytes -ge 1MB) { return "$([math]::Round($bytes/1MB, 2)) MB" }
    return "$bytes B"
}

function Show-Menu {
    Show-Header "Visualizador del Sistema 🖥️" "Información del sistema Windows"
    Write-Host "  ${Cyan}Opciones disponibles:${NC}"
    Write-Host ""
    Write-Host "  ${Green}1.${NC} Ver información del sistema (estilo neofetch)"
    Write-Host "  ${Green}2.${NC} Ver información completa"
    Write-Host "  ${Green}3.${NC} Ver solo información de hardware"
    Write-Host "  ${Green}4.${NC} Ver herramientas de desarrollo instaladas"
    Write-Host "  ${Green}5.${NC} Ver información de red"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

function Show-WindowsAscii {
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
    Write-Host "${Cyan}${NC}"
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
    Write-Host "${Cyan}        ████████████████  ████████████████${NC}"
}

function Show-SystemInfo {
    Show-Header "Visualizador del Sistema 🖥️" "Información del sistema Windows"

    $os     = Get-CimInstance Win32_OperatingSystem
    $cpu    = Get-CimInstance Win32_Processor | Select-Object -First 1
    $board  = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
    $gpu    = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $disks  = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

    $totalRAM  = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM   = [math]::Round($os.FreePhysicalMemory  / 1MB, 2)
    $usedRAM   = [math]::Round($totalRAM - $freeRAM, 2)
    $ramPct    = [math]::Round(($usedRAM / $totalRAM) * 100, 1)
    $uptime    = (Get-Date) - $os.LastBootUpTime
    $uptimeStr = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""

    $left  = @()
    $right = @(
        "${Green}${Bold}$env:USERNAME@$env:COMPUTERNAME${NC}",
        "${Gray}─────────────────────────────────────────${NC}",
        "${Cyan}OS:${NC}       $($os.Caption) $($os.OSArchitecture)",
        "${Cyan}Version:${NC}  $($os.Version) (Build $($os.BuildNumber))",
        "${Cyan}Host:${NC}     $(if ($board) {"$($board.Manufacturer) $($board.Product)"} else {"N/A"})",
        "${Cyan}Uptime:${NC}   $uptimeStr",
        "${Cyan}Shell:${NC}    PowerShell $($PSVersionTable.PSVersion)",
        "${Cyan}CPU:${NC}      $($cpu.Name.Trim())",
        "${Cyan}Núcleos:${NC}  $($cpu.NumberOfCores) físicos / $($cpu.NumberOfLogicalProcessors) lógicos",
        "${Cyan}GPU:${NC}      $($gpu.Name)",
        "${Cyan}RAM:${NC}      $usedRAM GB / $totalRAM GB ($ramPct%)"
    )

    foreach ($disk in $disks) {
        $totalGB  = [math]::Round($disk.Size / 1GB, 2)
        $freeGB   = [math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB   = [math]::Round($totalGB - $freeGB, 2)
        $right   += "${Cyan}Disco $($disk.DeviceID):${NC} $usedGB GB / $totalGB GB"
    }

    foreach ($line in $right) {
        Write-Host "  $line"
    }

    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-FullInfo {
    Write-Host ""
    Write-Progress-Msg "Obteniendo información completa del sistema..."
    Write-Host ""

    $os    = Get-CimInstance Win32_OperatingSystem
    $cpu   = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu   = Get-CimInstance Win32_VideoController
    $net   = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

    $totalRAM  = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM   = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM   = [math]::Round($totalRAM - $freeRAM, 2)
    $ramPct    = [math]::Round(($usedRAM / $totalRAM) * 100, 1)

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    Write-Host "${Cyan}═══ Sistema Operativo ═══${NC}"
    Write-Host "  OS:           $($os.Caption)"
    Write-Host "  Versión:      $($os.Version)"
    Write-Host "  Build:        $($os.BuildNumber)"
    Write-Host "  Arquitectura: $($os.OSArchitecture)"
    Write-Host "  Directorio:   $($os.WindowsDirectory)"
    Write-Host ""

    Write-Host "${Cyan}═══ Procesador ═══${NC}"
    Write-Host "  CPU:              $($cpu.Name.Trim())"
    Write-Host "  Núcleos físicos:  $($cpu.NumberOfCores)"
    Write-Host "  Hilos lógicos:    $($cpu.NumberOfLogicalProcessors)"
    Write-Host "  Frecuencia máx:   $($cpu.MaxClockSpeed) MHz"
    Write-Host ""

    Write-Host "${Cyan}═══ Memoria RAM ═══${NC}"
    Write-Host "  Total: $totalRAM GB  |  Usada: $usedRAM GB ($ramPct%)  |  Libre: $freeRAM GB"
    Write-Host ""

    Write-Host "${Cyan}═══ GPU ═══${NC}"
    foreach ($g in $gpu) {
        Write-Host "  $($g.Name)"
        Write-Host "    VRAM: $([math]::Round($g.AdapterRAM/1GB,2)) GB  |  Driver: $($g.DriverVersion)"
    }
    Write-Host ""

    Write-Host "${Cyan}═══ Discos ═══${NC}"
    Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object {
        $totalGB = [math]::Round($_.Size / 1GB, 2)
        $freeGB  = [math]::Round($_.FreeSpace / 1GB, 2)
        $usedGB  = [math]::Round($totalGB - $freeGB, 2)
        Write-Host "  $($_.DeviceID)  $usedGB GB / $totalGB GB libre: $freeGB GB"
    }
    Write-Host ""

    Write-Host "${Cyan}═══ Red ═══${NC}"
    foreach ($adapter in $net) {
        $ip = (Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
        if ($ip) { Write-Host "  $($adapter.Name): $ip ($([math]::Round($adapter.LinkSpeed/1MB,0)) Mbps)" }
    }
    Write-Host ""

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-HardwareInfo {
    Write-Host ""
    Write-Progress-Msg "Mostrando información de hardware..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    $cpu      = Get-CimInstance Win32_Processor | Select-Object -First 1
    $memMods  = Get-CimInstance Win32_PhysicalMemory
    $gpu      = Get-CimInstance Win32_VideoController
    $disksDrv = Get-CimInstance Win32_DiskDrive
    $monitors = Get-CimInstance Win32_DesktopMonitor -ErrorAction SilentlyContinue

    Write-Host "${Cyan}CPU:${NC} $($cpu.Name.Trim())"
    Write-Host "  Núcleos: $($cpu.NumberOfCores)  Hilos: $($cpu.NumberOfLogicalProcessors)  Max: $($cpu.MaxClockSpeed) MHz"
    Write-Host ""

    Write-Host "${Cyan}RAM:${NC}"
    $memTotal = ($memMods | Measure-Object -Property Capacity -Sum).Sum
    Write-Host "  Total: $([math]::Round($memTotal/1GB,2)) GB en $($memMods.Count) módulo(s)"
    foreach ($m in $memMods) {
        Write-Host "    $($m.DeviceLocator): $([math]::Round($m.Capacity/1GB,2)) GB @ $($m.Speed) MHz"
    }
    Write-Host ""

    Write-Host "${Cyan}GPU:${NC}"
    foreach ($g in $gpu) {
        Write-Host "  $($g.Name)"
        Write-Host "    VRAM: $([math]::Round($g.AdapterRAM/1GB,2)) GB  Driver: $($g.DriverVersion)"
    }
    Write-Host ""

    Write-Host "${Cyan}Discos físicos:${NC}"
    foreach ($disk in $disksDrv) {
        Write-Host "  $($disk.Model): $([math]::Round($disk.Size/1GB,2)) GB ($($disk.MediaType))"
    }
    Write-Host ""

    if ($monitors) {
        Write-Host "${Cyan}Monitores:${NC}"
        foreach ($m in $monitors) {
            Write-Host "  $($m.Name)$(if ($m.ScreenWidth) {" - $($m.ScreenWidth)x$($m.ScreenHeight)"})"
        }
        Write-Host ""
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-DevTools {
    Write-Host ""
    Write-Progress-Msg "Verificando herramientas de desarrollo instaladas..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Herramientas de Desarrollo:${NC}"
    Write-Host ""

    @(
        @{Name="Node.js";    Cmd="node";    Args="--version"},
        @{Name="npm";        Cmd="npm";     Args="--version"},
        @{Name="pnpm";       Cmd="pnpm";    Args="--version"},
        @{Name="Python";     Cmd="python";  Args="--version"},
        @{Name="pip";        Cmd="pip";     Args="--version"},
        @{Name="Git";        Cmd="git";     Args="--version"},
        @{Name="Go";         Cmd="go";      Args="version"},
        @{Name="Rust";       Cmd="rustc";   Args="--version"},
        @{Name="Docker";     Cmd="docker";  Args="--version"},
        @{Name="kubectl";    Cmd="kubectl"; Args="version --client --short 2>$null"},
        @{Name="dotnet";     Cmd="dotnet";  Args="--version"},
        @{Name="PowerShell"; Cmd="pwsh";    Args="--version"}
    ) | ForEach-Object {
        try {
            $version = & $_.Cmd ($_.Args -split " ") 2>&1 | Select-Object -First 1
            if ($LASTEXITCODE -eq 0 -or $version) {
                Write-Host "  ${Green}✓${NC} $($_.Name.PadRight(12)) ${Cyan}$version${NC}"
            } else {
                Write-Host "  ${Gray}✗${NC} $($_.Name.PadRight(12)) ${Gray}No instalado${NC}"
            }
        } catch {
            Write-Host "  ${Gray}✗${NC} $($_.Name.PadRight(12)) ${Gray}No instalado${NC}"
        }
    }

    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-NetworkInfo {
    Write-Host ""
    Write-Progress-Msg "Obteniendo información de red..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    Write-Host "${Cyan}Adaptadores activos:${NC}"
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $ip  = (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
        $ip6 = (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue |
                Where-Object { $_.IPAddress -notmatch "^fe80" }).IPAddress | Select-Object -First 1
        Write-Host "  ${Green}$($_.Name)${NC}"
        Write-Host "    IPv4:  ${Cyan}$(if ($ip)  {$ip}  else {'N/A'})${NC}"
        Write-Host "    IPv6:  ${Gray}$(if ($ip6) {$ip6} else {'N/A'})${NC}"
        Write-Host "    MAC:   $($_.MacAddress)"
        Write-Host "    Speed: $([math]::Round($_.LinkSpeed/1MB,0)) Mbps"
    }

    Write-Host ""
    Write-Host "${Cyan}Servidores DNS:${NC}"
    (Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses |
        Select-Object -Unique | Where-Object { $_ } |
        ForEach-Object { Write-Host "  $_" }

    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

# =========================
#  Main Loop
# =========================

while ($true) {
    Show-Menu
    $option = Read-Host "${Yellow}Selecciona una opción${NC}"

    switch ($option) {
        "1" { Show-SystemInfo }
        "2" { Show-FullInfo }
        "3" { Show-HardwareInfo }
        "4" { Show-DevTools }
        "5" { Show-NetworkInfo }
        "0" { Write-Host ""; Write-Success "¡Hasta luego!"; exit 0 }
        default { Write-Host ""; Write-Host "  ${Red}✗${NC} Opción inválida"; Write-Host "" }
    }

    Read-Host "${Cyan}Presiona Enter para continuar...${NC}" | Out-Null
}
