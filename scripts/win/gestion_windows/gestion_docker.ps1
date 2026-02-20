# Script de gestión de contenedores Docker en Windows
# Permite listar, iniciar, detener, reiniciar, inspeccionar y limpiar contenedores

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
    Show-Header "Gestión de Docker 🐳" "Contenedores e imágenes"
    Write-Host "  ${Cyan}Opciones disponibles:${NC}"
    Write-Host ""
    Write-Host "  ${Green}1.${NC} Listar contenedores (todos)"
    Write-Host "  ${Green}2.${NC} Listar contenedores en ejecución"
    Write-Host "  ${Green}3.${NC} Iniciar contenedor"
    Write-Host "  ${Green}4.${NC} Detener contenedor"
    Write-Host "  ${Green}5.${NC} Reiniciar contenedor"
    Write-Host "  ${Green}6.${NC} Ver logs de un contenedor"
    Write-Host "  ${Green}7.${NC} Abrir shell en un contenedor"
    Write-Host "  ${Green}8.${NC} Ver estadísticas en vivo (docker stats)"
    Write-Host "  ${Green}9.${NC} Eliminar contenedor"
    Write-Host "  ${Green}10.${NC} Limpiar contenedores detenidos"
    Write-Host "  ${Green}11.${NC} Listar imágenes"
    Write-Host "  ${Green}12.${NC} Limpiar imágenes sin uso"
    Write-Host "  ${Green}13.${NC} Ver versión e información de Docker"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

function Assert-DockerAvailable {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-Error-Msg "No se encontró el comando 'docker'. Instala Docker Desktop y vuelve a intentarlo."
        return $false
    }

    docker info | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Msg "Docker está instalado pero no disponible. Verifica que Docker Desktop esté en ejecución."
        return $false
    }

    return $true
}

function Get-DockerContainers {
    param([switch]$OnlyRunning)

    $args = @("ps", "--no-trunc", "--format", "{{json .}}")
    if (-not $OnlyRunning) {
        $args = @("ps", "-a", "--no-trunc", "--format", "{{json .}}")
    }

    $raw = docker @args 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        return @()
    }

    $items = @()
    foreach ($line in $raw) {
        if (-not $line) { continue }
        try {
            $obj = $line | ConvertFrom-Json
            $items += [PSCustomObject]@{
                ID      = $obj.ID
                Name    = $obj.Names
                Image   = $obj.Image
                Status  = $obj.Status
                State   = $obj.State
                Ports   = $obj.Ports
                Created = $obj.CreatedAt
            }
        }
        catch {
        }
    }

    return $items
}

function Select-Container {
    param(
        [string]$Prompt = "Selecciona un contenedor",
        [switch]$OnlyRunning
    )

    $containers = Get-DockerContainers -OnlyRunning:$OnlyRunning
    if (-not $containers -or $containers.Count -eq 0) {
        if ($OnlyRunning) {
            Write-Warning-Msg "No hay contenedores en ejecución"
        } else {
            Write-Warning-Msg "No hay contenedores disponibles"
        }
        return $null
    }

    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Bold}${Cyan}#   Nombre                Estado               Imagen${NC}"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    for ($i = 0; $i -lt $containers.Count; $i++) {
        $c = $containers[$i]
        $stateText = if ($c.State) { $c.State } else { $c.Status }
        $isRunning = $stateText -match "running|Up"
        $stateColor = if ($isRunning) { $Green } else { $Gray }
        $num = "$(($i + 1).ToString().PadRight(3))"

        $name = if ($c.Name.Length -gt 20) { $c.Name.Substring(0, 20) } else { $c.Name }
        $status = if ($stateText.Length -gt 20) { $stateText.Substring(0, 20) } else { $stateText }
        $image = if ($c.Image.Length -gt 22) { $c.Image.Substring(0, 22) + "…" } else { $c.Image }

        Write-Host "  ${Yellow}$num${NC} $($name.PadRight(20)) ${stateColor}$($status.PadRight(20))${NC} $image"
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""

    $sel = Read-Host "${Cyan}$Prompt (número)${NC}"
    if (-not ($sel -match '^\d+$')) {
        Write-Error-Msg "Selección inválida"
        return $null
    }

    $idx = [int]$sel - 1
    if ($idx -lt 0 -or $idx -ge $containers.Count) {
        Write-Error-Msg "Selección inválida"
        return $null
    }

    return $containers[$idx]
}

function List-Containers {
    Show-Header "Gestión de Docker 🐳" "Contenedores (todos)"
    Write-Progress-Msg "Obteniendo contenedores..."
    Write-Host ""

    $containers = Get-DockerContainers
    if (-not $containers -or $containers.Count -eq 0) {
        Write-Warning-Msg "No hay contenedores creados"
        Write-Host ""
        return
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Bold}${Cyan}Nombre                Estado               Imagen${NC}"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    foreach ($c in $containers) {
        $stateText = if ($c.State) { $c.State } else { $c.Status }
        $isRunning = $stateText -match "running|Up"
        $stateColor = if ($isRunning) { $Green } else { $Gray }

        $name = if ($c.Name.Length -gt 20) { $c.Name.Substring(0, 20) } else { $c.Name }
        $status = if ($stateText.Length -gt 20) { $stateText.Substring(0, 20) } else { $stateText }
        $image = if ($c.Image.Length -gt 28) { $c.Image.Substring(0, 28) + "…" } else { $c.Image }

        Write-Host "  $($name.PadRight(20)) ${stateColor}$($status.PadRight(20))${NC} $image"
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
    Write-Info "Total: $($containers.Count) contenedor(es)"
    Write-Host ""
}

function List-RunningContainers {
    Show-Header "Gestión de Docker 🐳" "Contenedores en ejecución"
    Write-Progress-Msg "Obteniendo contenedores activos..."
    Write-Host ""

    $containers = Get-DockerContainers -OnlyRunning
    if (-not $containers -or $containers.Count -eq 0) {
        Write-Warning-Msg "No hay contenedores en ejecución"
        Write-Host ""
        return
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Bold}${Cyan}Nombre                Estado               Puertos${NC}"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    foreach ($c in $containers) {
        $name = if ($c.Name.Length -gt 20) { $c.Name.Substring(0, 20) } else { $c.Name }
        $status = if ($c.Status.Length -gt 20) { $c.Status.Substring(0, 20) } else { $c.Status }
        $ports = if (-not $c.Ports) { "-" } elseif ($c.Ports.Length -gt 20) { $c.Ports.Substring(0, 20) + "…" } else { $c.Ports }

        Write-Host "  $($name.PadRight(20)) ${Green}$($status.PadRight(20))${NC} $ports"
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
    Write-Info "Total en ejecución: $($containers.Count)"
    Write-Host ""
}

function Start-Container {
    Show-Header "Gestión de Docker 🐳" "Iniciar contenedor"

    $container = Select-Container "Selecciona el contenedor a iniciar"
    if (-not $container) { return }

    Write-Host ""
    Write-Progress-Msg "Iniciando '$($container.Name)'..."
    docker start $container.ID | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Contenedor '$($container.Name)' iniciado"
    } else {
        Write-Error-Msg "No se pudo iniciar '$($container.Name)'"
    }
    Write-Host ""
}

function Stop-Container {
    Show-Header "Gestión de Docker 🐳" "Detener contenedor"

    $container = Select-Container "Selecciona el contenedor a detener" -OnlyRunning
    if (-not $container) { return }

    Write-Host ""
    Write-Progress-Msg "Deteniendo '$($container.Name)'..."
    docker stop $container.ID | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Contenedor '$($container.Name)' detenido"
    } else {
        Write-Error-Msg "No se pudo detener '$($container.Name)'"
    }
    Write-Host ""
}

function Restart-Container {
    Show-Header "Gestión de Docker 🐳" "Reiniciar contenedor"

    $container = Select-Container "Selecciona el contenedor a reiniciar"
    if (-not $container) { return }

    Write-Host ""
    Write-Progress-Msg "Reiniciando '$($container.Name)'..."
    docker restart $container.ID | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Contenedor '$($container.Name)' reiniciado"
    } else {
        Write-Error-Msg "No se pudo reiniciar '$($container.Name)'"
    }
    Write-Host ""
}

function Show-ContainerLogs {
    Show-Header "Gestión de Docker 🐳" "Logs de contenedor"

    $container = Select-Container "Selecciona el contenedor para ver logs"
    if (-not $container) { return }

    $tail = Read-Host "${Cyan}Número de líneas a mostrar${NC} [${Gray}100${NC}]"
    if (-not $tail) { $tail = "100" }
    if (-not ($tail -match '^\d+$')) {
        Write-Error-Msg "Valor inválido"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Progress-Msg "Mostrando logs de '$($container.Name)'..."
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    docker logs --tail $tail $container.ID 2>&1
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Open-ContainerShell {
    Show-Header "Gestión de Docker 🐳" "Abrir shell en contenedor"

    $container = Select-Container "Selecciona el contenedor" -OnlyRunning
    if (-not $container) { return }

    Write-Host ""
    Write-Info "Intentando abrir bash en '$($container.Name)'..."
    Write-Host "${Gray}  (si no existe bash, se intentará sh)${NC}"
    Write-Host "${Gray}  (escribe 'exit' para volver)${NC}"
    Write-Host ""

    docker exec -it $container.ID bash
    if ($LASTEXITCODE -ne 0) {
        docker exec -it $container.ID sh
    }

    Write-Host ""
    Write-Success "Sesión cerrada"
    Write-Host ""
}

function Show-DockerStats {
    Show-Header "Gestión de Docker 🐳" "Estadísticas en vivo"

    Write-Info "Se abrirá 'docker stats'. Presiona Ctrl+C para volver al menú."
    Write-Host ""
    docker stats
    Write-Host ""
}

function Remove-Container {
    Show-Header "Gestión de Docker 🐳" "Eliminar contenedor"

    $container = Select-Container "Selecciona el contenedor a ELIMINAR"
    if (-not $container) { return }

    Write-Host ""
    Write-Warning-Msg "¡Esta acción es IRREVERSIBLE para el contenedor '$($container.Name)'!"
    $confirm = Read-Host "${Red}Escribe el nombre del contenedor para confirmar: ${NC}"
    if ($confirm -ne $container.Name) {
        Write-Info "El nombre no coincide. Operación cancelada"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Progress-Msg "Eliminando '$($container.Name)'..."
    docker rm -f $container.ID | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Contenedor '$($container.Name)' eliminado"
    } else {
        Write-Error-Msg "No se pudo eliminar '$($container.Name)'"
    }
    Write-Host ""
}

function Prune-StoppedContainers {
    Show-Header "Gestión de Docker 🐳" "Limpiar contenedores detenidos"

    Write-Warning-Msg "Se eliminarán todos los contenedores detenidos"
    $confirm = Read-Host "${Yellow}¿Continuar? (s/N)${NC}"
    if ($confirm -notmatch "^[sS]$") {
        Write-Info "Operación cancelada"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Progress-Msg "Eliminando contenedores detenidos..."
    docker container prune -f
    Write-Host ""
}

function List-Images {
    Show-Header "Gestión de Docker 🐳" "Imágenes disponibles"
    Write-Progress-Msg "Obteniendo imágenes..."
    Write-Host ""

    $images = docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $images | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Error-Msg "No se pudieron obtener las imágenes"
    }
    Write-Host ""
}

function Prune-Images {
    Show-Header "Gestión de Docker 🐳" "Limpiar imágenes sin uso"

    Write-Warning-Msg "Se eliminarán imágenes dangling/no utilizadas"
    $confirm = Read-Host "${Yellow}¿Continuar? (s/N)${NC}"
    if ($confirm -notmatch "^[sS]$") {
        Write-Info "Operación cancelada"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Progress-Msg "Eliminando imágenes sin uso..."
    docker image prune -f
    Write-Host ""
}

function Show-DockerInfo {
    Show-Header "Gestión de Docker 🐳" "Información de Docker"
    Write-Host ""

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Bold}${Cyan}Versión:${NC}"
    docker version --format "Client: {{.Client.Version}} | Server: {{.Server.Version}}" 2>&1 | ForEach-Object {
        if ($_) { Write-Host "  $_" }
    }

    Write-Host ""
    Write-Host "  ${Bold}${Cyan}Estado del engine:${NC}"
    docker info --format "Containers: {{.Containers}} (Running: {{.ContainersRunning}}) | Images: {{.Images}}" 2>&1 | ForEach-Object {
        if ($_) { Write-Host "  $_" }
    }
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

if (-not (Assert-DockerAvailable)) {
    Read-Host "${Cyan}Presiona Enter para salir...${NC}" | Out-Null
    exit 1
}

while ($true) {
    Show-Menu
    $option = Read-Host "${Yellow}Selecciona una opción${NC}"

    switch ($option) {
        "1"  { List-Containers }
        "2"  { List-RunningContainers }
        "3"  { Start-Container }
        "4"  { Stop-Container }
        "5"  { Restart-Container }
        "6"  { Show-ContainerLogs }
        "7"  { Open-ContainerShell }
        "8"  { Show-DockerStats }
        "9"  { Remove-Container }
        "10" { Prune-StoppedContainers }
        "11" { List-Images }
        "12" { Prune-Images }
        "13" { Show-DockerInfo }
        "0"  { Write-Host ""; Write-Success "¡Hasta luego!"; exit 0 }
        default { Write-Host ""; Write-Error-Msg "Opción inválida"; Write-Host "" }
    }

    Read-Host "${Cyan}Presiona Enter para continuar...${NC}" | Out-Null
}