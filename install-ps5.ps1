# Script de instalacion global - Compatible con Windows PowerShell 5.x
# Configura el PATH y crea alias para usar los scripts desde cualquier lugar

# Obtener directorio del proyecto
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Instalador Global de Scripts de Desarrollo              ║" -ForegroundColor Magenta
Write-Host "║   Windows PowerShell 5.x                                  ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Verificar version de PowerShell
$psVersion = $PSVersionTable.PSVersion.Major
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
if ($psVersion -lt 5) {
    Write-Host "ERROR: Se requiere PowerShell 5.0 o superior" -ForegroundColor Red
    Write-Host "Descarga Windows Management Framework 5.1:" -ForegroundColor Yellow
    Write-Host "  https://www.microsoft.com/en-us/download/details.aspx?id=54616" -ForegroundColor White
    exit 1
}

# Detectar perfil de PowerShell
$ProfilePath = $PROFILE.CurrentUserAllHosts
if (-not $ProfilePath) {
    $ProfilePath = $PROFILE
}

Write-Host "OK PowerShell $psVersion detectado" -ForegroundColor Green
Write-Host "OK Archivo de perfil: $ProfilePath" -ForegroundColor Green
Write-Host ""

# Crear directorio del perfil si no existe
$ProfileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)) {
    Write-Host "-> Creando directorio de perfil..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

# Crear perfil si no existe
if (-not (Test-Path $ProfilePath)) {
    Write-Host "-> Creando archivo de perfil..." -ForegroundColor Cyan
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}

# Verificar si ya esta instalado
$ProfileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($ProfileContent -and $ProfileContent -match '# Scripts Development Launcher') {
    Write-Host "AVISO: Ya existe una instalacion previa" -ForegroundColor Yellow
    $response = Read-Host "Deseas reinstalar? (s/n)"
    if ($response -notmatch '^[sS]$') {
        Write-Host "Instalacion cancelada" -ForegroundColor Blue
        exit 0
    }

    # Remover instalacion anterior
    Write-Host "-> Removiendo instalacion anterior..." -ForegroundColor Cyan
    $lines = Get-Content -Path $ProfilePath
    $newLines = @()
    $skip = $false
    foreach ($line in $lines) {
        if ($line -match '# Scripts Development Launcher') { $skip = $true }
        if (-not $skip) { $newLines += $line }
        if ($line -match '# End Scripts Development Launcher') { $skip = $false }
    }
    $newLines | Set-Content -Path $ProfilePath
}

# Agregar configuracion al perfil
Write-Host "-> Agregando configuracion al perfil..." -ForegroundColor Cyan

# Construir el bloque de configuracion linea a linea (compatible PS5)
$lines = @()
$lines += ""
$lines += "# Scripts Development Launcher"
$lines += "# Agregado automaticamente por install-ps5.ps1"
$lines += ('$env:DEVSCRIPTS_ROOT = "' + $ScriptRoot + '"')
$lines += '$env:PATH += ";$env:DEVSCRIPTS_ROOT"'
$lines += ""
$lines += "# Funcion para el lanzador"
$lines += "function devlauncher {"
$lines += '    & "$env:DEVSCRIPTS_ROOT\launcher.exe" @args'
$lines += "}"
$lines += ""
$lines += "# Alias corto"
$lines += "Set-Alias -Name dl -Value devlauncher"
$lines += ""
$lines += "# Funcion para ejecutar scripts directamente"
$lines += "function devscript {"
$lines += "    param("
$lines += '        [string]$ScriptName,'
$lines += '        [string[]]$Arguments'
$lines += "    )"
$lines += '    if (-not $ScriptName) {'
$lines += "        Write-Host 'Uso: devscript <nombre_script>'"
$lines += "        Write-Host 'Ejemplo: devscript dev.ps1'"
$lines += "        return"
$lines += "    }"
$lines += '    $searchPath = Join-Path "$env:DEVSCRIPTS_ROOT" "scripts\win"'
$lines += '    $script = Get-ChildItem -Path $searchPath -Recurse -File -Filter $ScriptName -ErrorAction SilentlyContinue |'
$lines += '               Where-Object { $_.DirectoryName -notmatch "\\lib$" } |'
$lines += "               Select-Object -First 1"
$lines += '    if (-not $script) {'
$lines += '        Write-Host "Script no encontrado: $ScriptName"'
$lines += "        return"
$lines += "    }"
$lines += '    Write-Host "Ejecutando: $($script.FullName)"'
$lines += '    if ($script.Extension -eq ".ps1") {'
$lines += '        & $script.FullName @Arguments'
$lines += '    } elseif ($script.Extension -eq ".bat") {'
$lines += '        cmd.exe /c $script.FullName @Arguments'
$lines += "    }"
$lines += "}"
$lines += ""
$lines += "# End Scripts Development Launcher"

Add-Content -Path $ProfilePath -Value $lines

Write-Host "OK Configuracion agregada exitosamente" -ForegroundColor Green
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "Instalacion completada!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "Para activar los cambios, ejecuta:" -ForegroundColor Cyan
Write-Host "   . `$PROFILE" -ForegroundColor Yellow
Write-Host ""
Write-Host "O simplemente cierra y abre una nueva terminal de PowerShell." -ForegroundColor Cyan
Write-Host ""
Write-Host "Comandos disponibles:" -ForegroundColor Magenta
Write-Host ""
Write-Host "  devlauncher  o  dl" -ForegroundColor Green
Write-Host "    Abre el lanzador interactivo de scripts"
Write-Host ""
Write-Host "  devscript <nombre>" -ForegroundColor Green
Write-Host "    Ejecuta un script por nombre directamente"
Write-Host "    Ejemplo: devscript instalar_go.ps1" -ForegroundColor Cyan
Write-Host ""
