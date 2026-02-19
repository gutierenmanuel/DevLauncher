# Script de control y monitoreo de procesos para Windows
# Permite ver, buscar, filtrar y gestionar procesos del sistema

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
function Write-Warning-Msg  { param($Msg); Write-Host "  ${Yellow}⚠${NC} $Msg" }
function Write-Error-Msg    { param($Msg); Write-Host "  ${Red}✗${NC} $Msg" }
function Write-Info         { param($Msg); Write-Host "  ${Cyan}ℹ${NC} $Msg" }

function Show-Menu {
    Show-Header "Control de Procesos 🔄" "Gestión y monitoreo del sistema"
    Write-Host "  ${Cyan}Opciones disponibles:${NC}"
    Write-Host ""
    Write-Host "  ${Green}1.${NC} Ver todos los procesos"
    Write-Host "  ${Green}2.${NC} Buscar proceso por nombre"
    Write-Host "  ${Green}3.${NC} Buscar proceso por puerto"
    Write-Host "  ${Green}4.${NC} Top 10 procesos (CPU)"
    Write-Host "  ${Green}5.${NC} Top 10 procesos (Memoria)"
    Write-Host "  ${Green}6.${NC} Terminar proceso"
    Write-Host "  ${Green}7.${NC} Ver árbol de procesos"
    Write-Host "  ${Green}8.${NC} Ver procesos que no responden"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

function List-AllProcesses {
    Write-Progress-Msg "Listando todos los procesos..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    Get-Process | Sort-Object CPU -Descending | Select-Object -First 30 |
        Format-Table -AutoSize `
            @{Label="PID";    Expression={$_.Id};                                    Width=7},
            @{Label="Nombre"; Expression={$_.ProcessName};                           Width=25},
            @{Label="CPU(s)"; Expression={[math]::Round($_.CPU, 2)};                Width=9},
            @{Label="Mem(MB)";Expression={[math]::Round($_.WorkingSet64/1MB, 2)};   Width=9},
            @{Label="Hilos";  Expression={$_.Threads.Count};                        Width=7}

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Info "Mostrando los primeros 30 procesos ordenados por CPU"
    Write-Host ""
}

function Search-ByName {
    Write-Host ""
    $processName = Read-Host "${Cyan}Introduce el nombre del proceso${NC}"
    if (-not $processName) { Write-Warning-Msg "Nombre vacío"; return }

    Write-Host ""
    Write-Progress-Msg "Buscando procesos que coincidan con '$processName'..."
    Write-Host ""

    $results = Get-Process -Name "*$processName*" -ErrorAction SilentlyContinue

    if (-not $results) {
        Write-Warning-Msg "No se encontraron procesos con el nombre '$processName'"
    } else {
        Write-Host "${Green}Procesos encontrados:${NC}"
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
        $results | Format-Table -AutoSize `
            Id, ProcessName,
            @{Label="CPU(s)"; Expression={[math]::Round($_.CPU, 2)}},
            @{Label="Mem(MB)";Expression={[math]::Round($_.WorkingSet64/1MB, 2)}}
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    }
    Write-Host ""
}

function Search-ByPort {
    Write-Host ""
    $port = Read-Host "${Cyan}Introduce el número de puerto${NC}"
    if (-not $port) { Write-Warning-Msg "Puerto vacío"; return }

    Write-Host ""
    Write-Progress-Msg "Buscando proceso usando el puerto $port..."
    Write-Host ""

    $tcpConns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    $udpConns = Get-NetUDPEndpoint   -LocalPort $port -ErrorAction SilentlyContinue

    if (-not $tcpConns -and -not $udpConns) {
        Write-Warning-Msg "No se encontraron procesos usando el puerto $port"
    } else {
        Write-Host "${Green}Proceso(s) usando el puerto ${port}:${NC}"
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
        foreach ($conn in ($tcpConns + $udpConns)) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            Write-Host "  Puerto: ${Cyan}$port${NC}  PID: ${Yellow}$($conn.OwningProcess)${NC}  Proceso: ${Green}$($proc.ProcessName)${NC}"
        }
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    }
    Write-Host ""
}

function Show-TopCPU {
    Write-Progress-Msg "Top 10 procesos por uso de CPU..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 |
        Format-Table -AutoSize `
            @{Label="PID";    Expression={$_.Id};                                    Width=7},
            @{Label="Nombre"; Expression={$_.ProcessName};                           Width=25},
            @{Label="CPU(s)"; Expression={[math]::Round($_.CPU, 2)};                Width=9},
            @{Label="Mem(MB)";Expression={[math]::Round($_.WorkingSet64/1MB, 2)};   Width=9}

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-TopMemory {
    Write-Progress-Msg "Top 10 procesos por uso de Memoria..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 |
        Format-Table -AutoSize `
            @{Label="PID";    Expression={$_.Id};                                    Width=7},
            @{Label="Nombre"; Expression={$_.ProcessName};                           Width=25},
            @{Label="Mem(MB)";Expression={[math]::Round($_.WorkingSet64/1MB, 2)};   Width=9},
            @{Label="CPU(s)"; Expression={[math]::Round($_.CPU, 2)};                Width=9}

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Stop-ProcessInteractive {
    Write-Host ""
    $pidInput = Read-Host "${Cyan}Introduce el PID del proceso a terminar${NC}"
    if (-not $pidInput) { Write-Warning-Msg "PID vacío"; return }

    $proc = Get-Process -Id $pidInput -ErrorAction SilentlyContinue
    if (-not $proc) {
        Write-Error-Msg "No existe un proceso con PID $pidInput"
        return
    }

    Write-Host ""
    Write-Info "Información del proceso:"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    $proc | Format-Table -AutoSize Id, ProcessName,
        @{Label="CPU(s)"; Expression={[math]::Round($_.CPU, 2)}},
        @{Label="Mem(MB)";Expression={[math]::Round($_.WorkingSet64/1MB, 2)}}
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    $confirm = Read-Host "${Yellow}¿Estás seguro de que quieres terminar este proceso? (s/N)${NC}"
    if ($confirm -notmatch "^[sS]$") { Write-Info "Operación cancelada"; return }

    Write-Host ""
    Write-Progress-Msg "Intentando terminar proceso $pidInput..."

    try {
        Stop-Process -Id $pidInput -ErrorAction Stop
        Start-Sleep -Milliseconds 500

        $stillRunning = Get-Process -Id $pidInput -ErrorAction SilentlyContinue
        if ($stillRunning) {
            Write-Warning-Msg "El proceso aún está activo"
            $forceConfirm = Read-Host "${Yellow}¿Quieres forzar la terminación? (s/N)${NC}"
            if ($forceConfirm -match "^[sS]$") {
                Stop-Process -Id $pidInput -Force -ErrorAction Stop
                Write-Success "Proceso $pidInput terminado forzadamente"
            }
        } else {
            Write-Success "Proceso $pidInput terminado correctamente"
        }
    } catch {
        Write-Error-Msg "No se pudo terminar el proceso: $($_.Exception.Message)"
    }
    Write-Host ""
}

function Show-ProcessTree {
    Write-Host ""
    Write-Progress-Msg "Mostrando árbol de procesos..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    $wmiProcs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
    $wmiProcs | Sort-Object ParentProcessId, ProcessId |
        Select-Object -First 40 |
        Format-Table -AutoSize `
            @{Label="ParentPID"; Expression={$_.ParentProcessId}; Width=10},
            @{Label="PID";       Expression={$_.ProcessId};       Width=7},
            @{Label="Nombre";    Expression={$_.Name};            Width=30}

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Info "Mostrando primeros 40 procesos. ParentPID indica el proceso padre."
    Write-Host ""
}

function Show-NotResponding {
    Write-Host ""
    Write-Progress-Msg "Buscando procesos que no responden..."
    Write-Host ""

    $allProcs     = Get-Process
    $notResponding = $allProcs | Where-Object { -not $_.Responding }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Green}Total de procesos:${NC}   $($allProcs.Count)"
    Write-Host "  ${Green}Respondiendo:${NC}        $(($allProcs | Where-Object { $_.Responding }).Count)"

    if ($notResponding.Count -gt 0) {
        Write-Host "  ${Red}No responden:${NC}        $($notResponding.Count)"
        Write-Host ""
        Write-Host "  ${Yellow}Procesos que no responden:${NC}"
        $notResponding | Format-Table -AutoSize Id, ProcessName,
            @{Label="Mem(MB)"; Expression={[math]::Round($_.WorkingSet64/1MB, 2)}}
    } else {
        Write-Host "  ${Green}No responden:${NC}        0 ✓"
    }
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
        "1" { List-AllProcesses }
        "2" { Search-ByName }
        "3" { Search-ByPort }
        "4" { Show-TopCPU }
        "5" { Show-TopMemory }
        "6" { Stop-ProcessInteractive }
        "7" { Show-ProcessTree }
        "8" { Show-NotResponding }
        "0" { Write-Host ""; Write-Success "¡Hasta luego!"; exit 0 }
        default { Write-Host ""; Write-Error-Msg "Opción inválida"; Write-Host "" }
    }

    Read-Host "${Cyan}Presiona Enter para continuar...${NC}" | Out-Null
}
