# Script de gestión de WSL (Windows Subsystem for Linux)
# Permite listar, instalar, eliminar, detener y administrar distros WSL

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
    Show-Header "Gestión de WSL 🐧" "Windows Subsystem for Linux"
    Write-Host "  ${Cyan}Opciones disponibles:${NC}"
    Write-Host ""
    Write-Host "  ${Green}1.${NC} Listar distros instaladas"
    Write-Host "  ${Green}2.${NC} Listar distros disponibles para instalar"
    Write-Host "  ${Green}3.${NC} Instalar una distro"
    Write-Host "  ${Green}4.${NC} Abrir terminal de una distro"
    Write-Host "  ${Green}5.${NC} Iniciar una distro detenida"
    Write-Host "  ${Green}6.${NC} Detener una distro"
    Write-Host "  ${Green}7.${NC} Detener todas las distros"
    Write-Host "  ${Green}7.${NC} Eliminar una distro"
    Write-Host "  ${Green}8.${NC} Eliminar una distro"
    Write-Host "  ${Green}9.${NC} Establecer distro por defecto"
    Write-Host "  ${Green}10.${NC} Exportar una distro"
    Write-Host "  ${Green}11.${NC} Importar una distro"
    Write-Host "  ${Green}12.${NC} Actualizar WSL"
    Write-Host "  ${Green}13.${NC} Ver versión e información de WSL"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

# ── Helpers ────────────────────────────────────────────────────────────────

function Get-WslDistros {
    # Devuelve lista de distros instaladas (nombres limpios, sin BOM/ANSI)
    $raw = wsl --list --verbose 2>&1
    $distros = @()
    foreach ($line in $raw) {
        $clean = $line -replace '\x00', '' -replace '\e\[[0-9;]*m', '' -replace '^\*\s+', '' -replace '^\s+', ''
        if ($clean -match '^(\S+)\s+(Running|Stopped|Installing)\s+(\d)') {
            $distros += [PSCustomObject]@{
                Name    = $Matches[1]
                State   = $Matches[2]
                Version = $Matches[3]
            }
        }
    }
    return $distros
}

function Select-Distro {
    param($Prompt = "Selecciona una distro")
    $distros = Get-WslDistros
    if (-not $distros) {
        Write-Warning-Msg "No hay distros WSL instaladas"
        return $null
    }

    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Bold}${Cyan}#   Nombre                     Estado      WSL${NC}"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    for ($i = 0; $i -lt $distros.Count; $i++) {
        $d = $distros[$i]
        $stateColor = if ($d.State -eq "Running") { $Green } else { $Gray }
        $num = "$(($i+1).ToString().PadRight(3))"
        Write-Host "  ${Yellow}$num${NC} $($d.Name.PadRight(30)) ${stateColor}$($d.State.PadRight(11))${NC} v$($d.Version)"
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""

    $sel = Read-Host "${Cyan}$Prompt (número)${NC}"
    $idx = [int]$sel - 1
    if ($idx -lt 0 -or $idx -ge $distros.Count) {
        Write-Error-Msg "Selección inválida"
        return $null
    }
    return $distros[$idx].Name
}

# ── Funciones principales ──────────────────────────────────────────────────

function List-Distros {
    Show-Header "Gestión de WSL 🐧" "Distros instaladas"
    Write-Progress-Msg "Obteniendo distros instaladas..."
    Write-Host ""

    $distros = Get-WslDistros
    if (-not $distros) {
        Write-Warning-Msg "No hay distros WSL instaladas"
        Write-Host ""
        return
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Bold}${Cyan}Nombre                     Estado      WSL${NC}"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    foreach ($d in $distros) {
        $stateColor = if ($d.State -eq "Running") { $Green } else { $Gray }
        Write-Host "  $($d.Name.PadRight(30)) ${stateColor}$($d.State.PadRight(11))${NC} v$($d.Version)"
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
    Write-Info "Total: $($distros.Count) distro(s)"
    Write-Host ""
}

function List-Available {
    Show-Header "Gestión de WSL 🐧" "Distros disponibles para instalar"
    Write-Progress-Msg "Obteniendo lista de distros disponibles..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    wsl --list --online 2>&1 | ForEach-Object {
        $clean = $_ -replace '\x00', '' -replace '\e\[[0-9;]*m', ''
        if ($clean.Trim()) { Write-Host "  $clean" }
    }
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Install-Distro {
    Show-Header "Gestión de WSL 🐧" "Instalar distro"

    Write-Host ""
    Write-Host "${Cyan}  Distros comunes:${NC}"
    Write-Host "  ${Gray}Ubuntu, Ubuntu-22.04, Ubuntu-24.04, Debian, kali-linux,"
    Write-Host "  openSUSE-Leap-15.5, OracleLinux_8_7, AlmaLinux-8${NC}"
    Write-Host ""

    $name = Read-Host "${Cyan}Nombre de la distro a instalar${NC}"
    if (-not $name) { Write-Warning-Msg "Nombre vacío"; return }

    Write-Host ""
    Write-Progress-Msg "Instalando '$name'... (puede tardar varios minutos)"
    Write-Host ""

    wsl --install -d $name
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Success "Distro '$name' instalada correctamente"
    } else {
        Write-Host ""
        Write-Error-Msg "Error al instalar '$name'. Verifica el nombre con la opción 2."
    }
    Write-Host ""
}

function Open-Terminal {
    Show-Header "Gestión de WSL 🐧" "Abrir terminal"

    $name = Select-Distro "Selecciona la distro a abrir"
    if (-not $name) { return }

    Write-Host ""
    Write-Success "Abriendo terminal de '$name'..."
    Write-Host "${Gray}  (escribe 'exit' para volver)${NC}"
    Write-Host ""
    wsl -d $name
    Write-Host ""
    Write-Success "Sesión de '$name' cerrada"
    Write-Host ""
}

function Start-Distro {
    Show-Header "Gestión de WSL 🐧" "Iniciar distro"

    $name = Select-Distro "Selecciona la distro a iniciar"
    if (-not $name) { return }

    Write-Host ""
    Write-Progress-Msg "Iniciando '$name'..."

    wsl -d $name --exec echo "" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Distro '$name' iniciada correctamente"
    } else {
        Write-Error-Msg "No se pudo iniciar '$name'"
    }
    Write-Host ""
}

function Stop-Distro {
    Show-Header "Gestión de WSL 🐧" "Detener distro"

    $name = Select-Distro "Selecciona la distro a detener"
    if (-not $name) { return }

    Write-Host ""
    Write-Progress-Msg "Deteniendo '$name'..."

    wsl --terminate $name 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Distro '$name' detenida correctamente"
    } else {
        Write-Error-Msg "No se pudo detener '$name' (puede que ya estuviera detenida)"
    }
    Write-Host ""
}

function Stop-AllDistros {
    Show-Header "Gestión de WSL 🐧" "Detener todas las distros"

    Write-Host ""
    $confirm = Read-Host "${Yellow}¿Detener TODAS las distros WSL en ejecución? (s/N)${NC}"
    if ($confirm -notmatch "^[sS]$") { Write-Info "Operación cancelada"; Write-Host ""; return }

    Write-Host ""
    Write-Progress-Msg "Apagando WSL completo..."

    wsl --shutdown 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Todas las distros WSL han sido detenidas"
    } else {
        Write-Error-Msg "Error al apagar WSL"
    }
    Write-Host ""
}

function Remove-Distro {
    Show-Header "Gestión de WSL 🐧" "Eliminar distro"

    $name = Select-Distro "Selecciona la distro a ELIMINAR"
    if (-not $name) { return }

    Write-Host ""
    Write-Warning-Msg "¡Esta acción es IRREVERSIBLE! Se eliminarán todos los datos de '$name'"
    Write-Host ""
    $confirm = Read-Host "${Red}Escribe el nombre de la distro para confirmar: ${NC}"
    if ($confirm -ne $name) {
        Write-Info "El nombre no coincide. Operación cancelada"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Progress-Msg "Eliminando '$name'..."

    wsl --unregister $name 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Distro '$name' eliminada correctamente"
    } else {
        Write-Error-Msg "No se pudo eliminar '$name'"
    }
    Write-Host ""
}

function Set-DefaultDistro {
    Show-Header "Gestión de WSL 🐧" "Establecer distro por defecto"

    $name = Select-Distro "Selecciona la distro que será la predeterminada"
    if (-not $name) { return }

    Write-Host ""
    Write-Progress-Msg "Estableciendo '$name' como distro por defecto..."

    wsl --set-default $name 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "'$name' establecida como distro por defecto"
    } else {
        Write-Error-Msg "No se pudo establecer '$name' como distro por defecto"
    }
    Write-Host ""
}

function Export-Distro {
    Show-Header "Gestión de WSL 🐧" "Exportar distro"

    $name = Select-Distro "Selecciona la distro a exportar"
    if (-not $name) { return }

    Write-Host ""
    $defaultPath = "$env:USERPROFILE\Desktop\${name}.tar"
    $path = Read-Host "${Cyan}Ruta destino del archivo .tar${NC} [${Gray}$defaultPath${NC}]"
    if (-not $path) { $path = $defaultPath }

    Write-Host ""
    Write-Progress-Msg "Exportando '$name' a '$path'... (puede tardar varios minutos)"

    wsl --export $name $path
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Distro '$name' exportada en: $path"
    } else {
        Write-Error-Msg "Error al exportar '$name'"
    }
    Write-Host ""
}

function Import-Distro {
    Show-Header "Gestión de WSL 🐧" "Importar distro"

    Write-Host ""
    $name = Read-Host "${Cyan}Nombre para la nueva distro${NC}"
    if (-not $name) { Write-Warning-Msg "Nombre vacío"; return }

    $installPath = Read-Host "${Cyan}Directorio de instalación${NC} [${Gray}$env:USERPROFILE\WSL\$name${NC}]"
    if (-not $installPath) { $installPath = "$env:USERPROFILE\WSL\$name" }

    $tarPath = Read-Host "${Cyan}Ruta del archivo .tar a importar${NC}"
    if (-not $tarPath -or -not (Test-Path $tarPath)) {
        Write-Error-Msg "Archivo no encontrado: $tarPath"
        return
    }

    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }

    Write-Host ""
    Write-Progress-Msg "Importando '$name' desde '$tarPath'..."

    wsl --import $name $installPath $tarPath
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Distro '$name' importada correctamente"
    } else {
        Write-Error-Msg "Error al importar la distro"
    }
    Write-Host ""
}

function Update-Wsl {
    Show-Header "Gestión de WSL 🐧" "Actualizar WSL"
    Write-Host ""
    Write-Progress-Msg "Actualizando WSL..."
    Write-Host ""

    wsl --update
    Write-Host ""
    if ($LASTEXITCODE -eq 0) {
        Write-Success "WSL actualizado correctamente"
    } else {
        Write-Warning-Msg "La actualización puede requerir permisos de administrador"
    }
    Write-Host ""
}

function Show-WslInfo {
    Show-Header "Gestión de WSL 🐧" "Información de WSL"
    Write-Host ""

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "  ${Bold}${Cyan}Versión de WSL:${NC}"

    wsl --version 2>&1 | ForEach-Object {
        $clean = $_ -replace '\x00', '' -replace '\e\[[0-9;]*m', ''
        if ($clean.Trim()) { Write-Host "  $clean" }
    }

    Write-Host ""
    Write-Host "  ${Bold}${Cyan}Distros instaladas:${NC}"
    $distros = Get-WslDistros
    if ($distros) {
        foreach ($d in $distros) {
            $stateColor = if ($d.State -eq "Running") { $Green } else { $Gray }
            Write-Host "  $($d.Name.PadRight(30)) ${stateColor}$($d.State)${NC}  (WSL v$($d.Version))"
        }
    } else {
        Write-Host "  ${Gray}Ninguna distro instalada${NC}"
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
        "1"  { List-Distros }
        "2"  { List-Available }
        "3"  { Install-Distro }
        "4"  { Open-Terminal }
        "5"  { Start-Distro }
        "6"  { Stop-Distro }
        "7"  { Stop-AllDistros }
        "8"  { Remove-Distro }
        "9"  { Set-DefaultDistro }
        "10" { Export-Distro }
        "11" { Import-Distro }
        "12" { Update-Wsl }
        "13" { Show-WslInfo }
        "0"  { Write-Host ""; Write-Success "¡Hasta luego!"; exit 0 }
        default { Write-Host ""; Write-Error-Msg "Opción inválida"; Write-Host "" }
    }

    Read-Host "${Cyan}Presiona Enter para continuar...${NC}" | Out-Null
}
