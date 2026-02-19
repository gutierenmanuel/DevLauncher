# Script de instalacion global - Compatible con PowerShell 7.x (pwsh)
# Configura el PATH y crea alias para usar los scripts desde cualquier lugar

# Colores ANSI (PS6+)
$Green  = "`e[32m"
$Blue   = "`e[34m"
$Yellow = "`e[33m"
$Purple = "`e[35m"
$Cyan   = "`e[36m"
$NC     = "`e[0m"

# Obtener directorio del proyecto
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Verificar que se esta corriendo en PS7+
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 7) {
    Write-Host "ERROR: Este script requiere PowerShell 7 (pwsh)." -ForegroundColor Red
    Write-Host "Tu version actual: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor Cyan
    Write-Host "  1. Instala PowerShell 7:  .\scripts\win\instaladores\install-powershell7.bat" -ForegroundColor White
    Write-Host "  2. Usa el instalador PS5: .\install-ps5.ps1" -ForegroundColor White
    exit 1
}

Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║   Instalador Global de Scripts de Desarrollo 🚀           ║${NC}"
Write-Host "${Purple}║   PowerShell 7.x                                          ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Detectar perfil de PowerShell 7
$ProfilePath = $PROFILE.CurrentUserAllHosts
if (-not $ProfilePath) {
    $ProfilePath = $PROFILE
}

Write-Host "${Green}✓ PowerShell $($PSVersionTable.PSVersion) detectado${NC}"
Write-Host "${Green}✓ Archivo de perfil: $ProfilePath${NC}"
Write-Host ""

# Crear directorio del perfil si no existe
$ProfileDir = Split-Path -Parent $ProfilePath
if (-not (Test-Path $ProfileDir)) {
    Write-Host "${Cyan}→ Creando directorio de perfil...${NC}"
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

# Crear perfil si no existe
if (-not (Test-Path $ProfilePath)) {
    Write-Host "${Cyan}→ Creando archivo de perfil...${NC}"
    New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
}

# Verificar si ya esta instalado
$ProfileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($ProfileContent -and $ProfileContent -match '# Scripts Development Launcher') {
    Write-Host "${Yellow}⚠ Ya existe una instalacion previa${NC}"
    $response = Read-Host "Deseas reinstalar? (s/n)"
    if ($response -notmatch '^[sS]$') {
        Write-Host "${Blue}Instalacion cancelada${NC}"
        exit 0
    }

    # Remover instalacion anterior
    Write-Host "${Cyan}→ Removiendo instalacion anterior...${NC}"
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
Write-Host "${Cyan}→ Agregando configuracion al perfil...${NC}"

# Construir bloque de configuracion linea a linea (evita ambiguedades de here-string)
$cfgLines = @()
$cfgLines += ""
$cfgLines += "# Scripts Development Launcher"
$cfgLines += "# Agregado automaticamente por install-ps7.ps1"
$cfgLines += ('$env:DEVSCRIPTS_ROOT = "' + $ScriptRoot + '"')
$cfgLines += '$env:PATH += ";$env:DEVSCRIPTS_ROOT"'
$cfgLines += ""
$cfgLines += "# Funcion para el lanzador"
$cfgLines += "function devlauncher {"
$cfgLines += '    & "$env:DEVSCRIPTS_ROOT\launcher.exe" @args'
$cfgLines += "}"
$cfgLines += ""
$cfgLines += "# Alias corto"
$cfgLines += "Set-Alias -Name dl -Value devlauncher"
$cfgLines += ""
$cfgLines += "# Funcion para ejecutar scripts directamente"
$cfgLines += "function devscript {"
$cfgLines += "    param("
$cfgLines += '        [Parameter(Mandatory = $false)]'
$cfgLines += '        [string]$ScriptName,'
$cfgLines += '        [Parameter(ValueFromRemainingArguments = $true)]'
$cfgLines += '        [string[]]$Arguments'
$cfgLines += "    )"
$cfgLines += '    if (-not $ScriptName) {'
$cfgLines += "        Write-Host 'Uso: devscript <nombre_script>'"
$cfgLines += "        Write-Host 'Ejemplo: devscript dev.ps1'"
$cfgLines += "        return"
$cfgLines += "    }"
$cfgLines += '    $searchPath = Join-Path "$env:DEVSCRIPTS_ROOT" "scripts\win"'
$cfgLines += '    $script = Get-ChildItem -Path $searchPath -Recurse -File -Filter $ScriptName -ErrorAction SilentlyContinue |'
$cfgLines += '               Where-Object { $_.DirectoryName -notmatch "\\lib$" } |'
$cfgLines += "               Select-Object -First 1"
$cfgLines += '    if (-not $script) {'
$cfgLines += '        Write-Host "Script no encontrado: $ScriptName"'
$cfgLines += "        return"
$cfgLines += "    }"
$cfgLines += '    Write-Host "Ejecutando: $($script.FullName)"'
$cfgLines += '    if ($script.Extension -eq ".ps1") {'
$cfgLines += '        & $script.FullName @Arguments'
$cfgLines += '    } elseif ($script.Extension -eq ".bat") {'
$cfgLines += '        cmd.exe /c $script.FullName @Arguments'
$cfgLines += "    }"
$cfgLines += "}"
$cfgLines += ""
$cfgLines += "# Autocompletado para devscript (PS7)"
$cfgLines += "Register-ArgumentCompleter -CommandName devscript -ParameterName ScriptName -ScriptBlock {"
$cfgLines += '    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)'
$cfgLines += '    $searchPath = Join-Path "$env:DEVSCRIPTS_ROOT" "scripts\win"'
$cfgLines += '    Get-ChildItem -Path $searchPath -Recurse -File -Include "*.ps1","*.bat" -ErrorAction SilentlyContinue |'
$cfgLines += '        Where-Object { $_.DirectoryName -notmatch "\\lib$" -and $_.Name -like "$wordToComplete*" } |'
$cfgLines += '        ForEach-Object { $_.Name }'
$cfgLines += "}"
$cfgLines += ""
$cfgLines += "# End Scripts Development Launcher"

Add-Content -Path $ProfilePath -Value $cfgLines

Write-Host "${Green}✓ Configuracion agregada exitosamente${NC}"
Write-Host ""

Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✨ Instalacion completada!${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Cyan}Para activar los cambios, ejecuta:${NC}"
Write-Host "   ${Yellow}. `$PROFILE${NC}"
Write-Host ""
Write-Host "${Cyan}O simplemente cierra y abre una nueva terminal de PowerShell 7.${NC}"
Write-Host ""
Write-Host "${Purple}Comandos disponibles:${NC}"
Write-Host ""
Write-Host "  ${Green}devlauncher${NC}  o  ${Green}dl${NC}"
Write-Host "    Abre el lanzador interactivo de scripts"
Write-Host ""
Write-Host "  ${Green}devscript <nombre>${NC}"
Write-Host "    Ejecuta un script por nombre directamente"
Write-Host "    Ejemplo: ${Cyan}devscript instalar_go.ps1${NC}"
Write-Host ""
