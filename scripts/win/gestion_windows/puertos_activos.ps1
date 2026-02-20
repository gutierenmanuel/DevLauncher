# Script de monitoreo de puertos y conexiones de red para Windows
# Muestra puertos abiertos, procesos y conexiones establecidas

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

function Get-ProcName($pid) {
    (Get-Process -Id $pid -ErrorAction SilentlyContinue).ProcessName
}

function Show-Menu {
    Show-Header "Puertos Activos 🔌" "Monitoreo de red y conexiones"
    Write-Host "  ${Cyan}Opciones disponibles:${NC}"
    Write-Host ""
    Write-Host "  ${Green}1.${NC} Ver todos los puertos abiertos (Listening)"
    Write-Host "  ${Green}2.${NC} Ver puertos TCP"
    Write-Host "  ${Green}3.${NC} Ver puertos UDP"
    Write-Host "  ${Green}4.${NC} Buscar proceso por puerto específico"
    Write-Host "  ${Green}5.${NC} Ver conexiones establecidas"
    Write-Host "  ${Green}6.${NC} Ver puertos por proceso"
    Write-Host "  ${Green}7.${NC} Ver estadísticas de red"
    Write-Host "  ${Green}8.${NC} Escanear puerto específico"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

function Show-AllPorts {
    Write-Progress-Msg "Mostrando todos los puertos abiertos (LISTEN)..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Puertos TCP en escucha:${NC}"
    Write-Host ""

    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Sort-Object LocalPort |
        Select-Object `
            @{Label="Puerto";   Expression={$_.LocalPort}},
            @{Label="Dirección";Expression={$_.LocalAddress}},
            @{Label="PID";      Expression={$_.OwningProcess}},
            @{Label="Proceso";  Expression={Get-ProcName $_.OwningProcess}} |
        Format-Table -AutoSize

    Write-Host "${Bold}Puertos UDP en escucha:${NC}"
    Write-Host ""

    Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
        Sort-Object LocalPort |
        Select-Object -First 20 `
            @{Label="Puerto";   Expression={$_.LocalPort}},
            @{Label="Dirección";Expression={$_.LocalAddress}},
            @{Label="PID";      Expression={$_.OwningProcess}},
            @{Label="Proceso";  Expression={Get-ProcName $_.OwningProcess}} |
        Format-Table -AutoSize

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-TCPPorts {
    Write-Progress-Msg "Mostrando conexiones TCP..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Conexiones TCP:${NC}"
    Write-Host ""

    Get-NetTCPConnection -ErrorAction SilentlyContinue |
        Sort-Object State, LocalPort |
        Select-Object `
            @{Label="Estado";        Expression={$_.State}},
            @{Label="Puerto Local";  Expression={$_.LocalPort}},
            @{Label="IP Remota";     Expression={$_.RemoteAddress}},
            @{Label="Puerto Remoto"; Expression={$_.RemotePort}},
            @{Label="PID";           Expression={$_.OwningProcess}},
            @{Label="Proceso";       Expression={Get-ProcName $_.OwningProcess}} |
        Format-Table -AutoSize

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-UDPPorts {
    Write-Progress-Msg "Mostrando endpoints UDP..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Endpoints UDP:${NC}"
    Write-Host ""

    Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
        Sort-Object LocalPort |
        Select-Object `
            @{Label="Puerto";   Expression={$_.LocalPort}},
            @{Label="Dirección";Expression={$_.LocalAddress}},
            @{Label="PID";      Expression={$_.OwningProcess}},
            @{Label="Proceso";  Expression={Get-ProcName $_.OwningProcess}} |
        Format-Table -AutoSize

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Search-ByPort {
    Write-Host ""
    $port = Read-Host "${Cyan}Introduce el número de puerto${NC}"
    if (-not $port) { Write-Warning-Msg "Puerto vacío"; return }

    Write-Host ""
    Write-Progress-Msg "Buscando información del puerto $port..."
    Write-Host ""

    $tcpResults = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    $udpResults = Get-NetUDPEndpoint   -LocalPort $port -ErrorAction SilentlyContinue

    if ($tcpResults) {
        Write-Host "${Green}Puerto $port (TCP):${NC}"
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
        $tcpResults | Select-Object `
            @{Label="Estado";   Expression={$_.State}},
            LocalAddress,
            @{Label="PID";     Expression={$_.OwningProcess}},
            @{Label="Proceso"; Expression={Get-ProcName $_.OwningProcess}} | Format-Table -AutoSize
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    }

    if ($udpResults) {
        Write-Host "${Green}Puerto $port (UDP):${NC}"
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
        $udpResults | Select-Object `
            LocalAddress,
            @{Label="PID";     Expression={$_.OwningProcess}},
            @{Label="Proceso"; Expression={Get-ProcName $_.OwningProcess}} | Format-Table -AutoSize
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    }

    if (-not $tcpResults -and -not $udpResults) {
        Write-Warning-Msg "El puerto $port no está en uso"
    }
    Write-Host ""
}

function Show-Established {
    Write-Progress-Msg "Mostrando conexiones establecidas..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Conexiones TCP establecidas:${NC}"
    Write-Host ""

    $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue

    $connections | Sort-Object RemoteAddress | Select-Object -First 30 `
        @{Label="IP Local";       Expression={$_.LocalAddress}},
        @{Label="Puerto Local";   Expression={$_.LocalPort}},
        @{Label="IP Remota";      Expression={$_.RemoteAddress}},
        @{Label="Puerto Remoto";  Expression={$_.RemotePort}},
        @{Label="PID";            Expression={$_.OwningProcess}},
        @{Label="Proceso";        Expression={Get-ProcName $_.OwningProcess}} |
        Format-Table -AutoSize

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Info "Total de conexiones establecidas: $($connections.Count)"
    Write-Host ""
}

function Show-PortsByProcess {
    Write-Host ""
    $processName = Read-Host "${Cyan}Introduce el nombre del proceso${NC}"
    if (-not $processName) { Write-Warning-Msg "Nombre vacío"; return }

    Write-Host ""
    Write-Progress-Msg "Buscando puertos usados por '$processName'..."
    Write-Host ""

    $procs = Get-Process -Name "*$processName*" -ErrorAction SilentlyContinue
    if (-not $procs) { Write-Warning-Msg "No se encontró el proceso '$processName'"; return }

    $pids    = $procs.Id
    $results = Get-NetTCPConnection -ErrorAction SilentlyContinue |
               Where-Object { $pids -contains $_.OwningProcess }

    if (-not $results) {
        Write-Warning-Msg "No se encontraron puertos TCP usados por '$processName'"
    } else {
        Write-Host "${Green}Puertos usados por ${processName}:${NC}"
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
        $results | Select-Object `
            @{Label="Estado";        Expression={$_.State}},
            LocalAddress,
            @{Label="Puerto Local";  Expression={$_.LocalPort}},
            @{Label="IP Remota";     Expression={$_.RemoteAddress}},
            @{Label="Puerto Remoto"; Expression={$_.RemotePort}} | Format-Table -AutoSize
        Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    }
    Write-Host ""
}

function Show-NetworkStats {
    Write-Progress-Msg "Mostrando estadísticas de red..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Resumen de conexiones TCP:${NC}"
    Write-Host ""

    Get-NetTCPConnection -ErrorAction SilentlyContinue |
        Group-Object State | Sort-Object Count -Descending |
        ForEach-Object { Write-Host "  ${Cyan}$($_.Name):${NC} $($_.Count)" }

    Write-Host ""
    Write-Host "${Bold}Adaptadores de red activos:${NC}"
    Write-Host ""

    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } |
        Select-Object Name, @{Label="Velocidad";Expression={$_.LinkSpeed}}, MacAddress |
        Format-Table -AutoSize

    Write-Host "${Bold}Direcciones IP:${NC}"
    Write-Host ""

    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -ne "127.0.0.1" } |
        Select-Object InterfaceAlias, IPAddress, PrefixLength |
        Format-Table -AutoSize

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Test-PortConnectivity {
    Write-Host ""
    $port = Read-Host "${Cyan}Introduce el puerto a escanear${NC}"
    if (-not $port) { Write-Warning-Msg "Puerto vacío"; return }

    $hostInput = Read-Host "${Cyan}Introduce el host (Enter para localhost)${NC}"
    if (-not $hostInput) { $hostInput = "localhost" }

    Write-Host ""
    Write-Progress-Msg "Escaneando puerto $port en $hostInput..."
    Write-Host ""

    $result = Test-NetConnection -ComputerName $hostInput -Port $port `
              -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

    if ($result.TcpTestSucceeded) {
        Write-Success "Puerto $port está ABIERTO en $hostInput"
    } else {
        Write-Warning-Msg "Puerto $port está CERRADO o no responde en $hostInput"
    }
    Write-Host ""
}

# =========================
#  Main Loop
# =========================

while ($true) {
    Show-Menu
    $option = Read-Host "${Yellow}Selecciona una opción${NC}"

    switch ($option) {
        "1" { Show-AllPorts }
        "2" { Show-TCPPorts }
        "3" { Show-UDPPorts }
        "4" { Search-ByPort }
        "5" { Show-Established }
        "6" { Show-PortsByProcess }
        "7" { Show-NetworkStats }
        "8" { Test-PortConnectivity }
        "0" { Write-Host ""; Write-Success "¡Hasta luego!"; exit 0 }
        default { Write-Host ""; Write-Error-Msg "Opción inválida"; Write-Host "" }
    }

    Read-Host "${Cyan}Presiona Enter para continuar...${NC}" | Out-Null
}
