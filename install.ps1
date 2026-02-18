# Script de instalación global para los scripts de desarrollo (Windows)
# Configura el PATH y crea alias para usar los scripts desde cualquier lugar

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$Cyan = "`e[36m"
$NC = "`e[0m"

# Obtener directorio del proyecto
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║   Instalador Global de Scripts de Desarrollo 🚀           ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Detectar perfil de PowerShell
$ProfilePath = $PROFILE.CurrentUserAllHosts
if (-not $ProfilePath) {
    $ProfilePath = $PROFILE
}

Write-Host "${Green}✓ PowerShell detectado${NC}"
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

# Verificar si ya está instalado
$ProfileContent = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
if ($ProfileContent -and $ProfileContent -match '# Scripts Development Launcher') {
    Write-Host "${Yellow}⚠ Ya existe una instalación previa${NC}"
    $response = Read-Host "¿Deseas reinstalar? (s/n)"
    if ($response -notmatch '^[sS]$') {
        Write-Host "${Blue}Instalación cancelada${NC}"
        exit 0
    }
    
    # Remover instalación anterior
    Write-Host "${Cyan}→ Removiendo instalación anterior...${NC}"
    $lines = Get-Content -Path $ProfilePath
    $newLines = @()
    $skip = $false
    foreach ($line in $lines) {
        if ($line -match '# Scripts Development Launcher') {
            $skip = $true
        }
        if (-not $skip) {
            $newLines += $line
        }
        if ($line -match '# End Scripts Development Launcher') {
            $skip = $false
        }
    }
    $newLines | Set-Content -Path $ProfilePath
}

# Agregar configuración al perfil
Write-Host "${Cyan}→ Agregando configuración al perfil...${NC}"

$config = @"

# Scripts Development Launcher
# Agregado automáticamente por install.ps1
`$env:DEVSCRIPTS_ROOT = "$ScriptRoot"
`$env:PATH += ";`$env:DEVSCRIPTS_ROOT"

# Función para el lanzador
function devlauncher {
    & "`$env:DEVSCRIPTS_ROOT\launcher.exe" @args
}

# Alias corto
Set-Alias -Name dl -Value devlauncher

# Función para ejecutar scripts directamente
function devscript {
    param(
        [Parameter(Mandatory=`$false)]
        [string]`$ScriptName,
        [Parameter(ValueFromRemainingArguments=`$true)]
        [string[]]`$Arguments
    )
    
    if (-not `$ScriptName) {
        Write-Host "Uso: devscript <nombre_script>"
        Write-Host "Ejemplo: devscript dev.ps1"
        return
    }
    
    # Buscar en la carpeta win primero
    `$searchPath = Join-Path "`$env:DEVSCRIPTS_ROOT" "scripts\win"
    `$script = Get-ChildItem -Path `$searchPath -Recurse -File -Filter `$ScriptName -ErrorAction SilentlyContinue | 
               Where-Object { `$_.DirectoryName -notmatch '\\lib$' } | 
               Select-Object -First 1
    
    if (-not `$script) {
        Write-Host "Script no encontrado: `$ScriptName"
        return
    }
    
    Write-Host "Ejecutando: `$(`$script.FullName)"
    
    if (`$script.Extension -eq '.ps1') {
        & `$script.FullName @Arguments
    } elseif (`$script.Extension -eq '.bat') {
        cmd.exe /c `$script.FullName @Arguments
    }
}

# Autocompletado para devscript
Register-ArgumentCompleter -CommandName devscript -ParameterName ScriptName -ScriptBlock {
    param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)
    
    `$searchPath = Join-Path "`$env:DEVSCRIPTS_ROOT" "scripts\win"
    Get-ChildItem -Path `$searchPath -Recurse -File -Include "*.ps1","*.bat" -ErrorAction SilentlyContinue |
        Where-Object { `$_.DirectoryName -notmatch '\\lib$' -and `$_.Name -like "`$wordToComplete*" } |
        ForEach-Object { `$_.Name }
}

# End Scripts Development Launcher
"@

Add-Content -Path $ProfilePath -Value $config

Write-Host "${Green}✓ Configuración agregada exitosamente${NC}"
Write-Host ""

# Instrucciones finales
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✨ Instalación completada!${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Cyan}Para activar los cambios, ejecuta:${NC}"
Write-Host "   ${Yellow}. `$PROFILE${NC}"
Write-Host ""
Write-Host "${Cyan}O simplemente cierra y abre una nueva terminal de PowerShell.${NC}"
Write-Host ""
Write-Host "${Purple}Comandos disponibles:${NC}"
Write-Host ""
Write-Host "  ${Green}devlauncher${NC} o ${Green}dl${NC}"
Write-Host "    Abre el lanzador interactivo de scripts"
Write-Host ""
Write-Host "  ${Green}devscript <nombre>${NC}"
Write-Host "    Ejecuta un script por nombre directamente"
Write-Host "    Ejemplo: ${Cyan}devscript dev.ps1${NC}"
Write-Host "              ${Cyan}devscript init_frontend_project.ps1${NC}"
Write-Host ""
Write-Host "${Green}🎉 ¡Disfruta de tus scripts desde cualquier lugar!${NC}"
Write-Host ""
