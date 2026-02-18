# Script para instalar uv en Windows
# uv es una herramienta moderna ultra-rápida para gestión de paquetes Python

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$Cyan = "`e[36m"
$Gray = "`e[90m"
$NC = "`e[0m"

function Show-Header {
    param([string]$Title, [string]$Subtitle = "")
    Write-Host ""
    Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
    $titlePadded = "  $Title" + (" " * (57 - $Title.Length))
    Write-Host "${Purple}║${NC}$titlePadded${Purple}║${NC}"
    if ($Subtitle) {
        $subtitlePadded = "  $Subtitle" + (" " * (57 - $Subtitle.Length))
        Write-Host "${Purple}║${NC}$subtitlePadded${Purple}║${NC}"
    }
    Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
    Write-Host ""
}

Show-Header "Instalador de uv 🐍⚡" "Gestor de paquetes Python ultra-rápido"

# Verificar si uv ya está instalado
Write-Host "${Blue}→ Verificando instalación existente...${NC}"
$uvExists = $null
try {
    $uvExists = Get-Command uv -ErrorAction SilentlyContinue
    if ($uvExists) {
        Write-Host "${Yellow}⚠ uv ya está instalado${NC}"
        $uvVersion = & uv --version 2>&1
        Write-Host "${Green}Versión: $uvVersion${NC}"
        Write-Host ""
        $response = Read-Host "¿Deseas actualizar a la última versión? (s/n)"
        if ($response -notmatch '^[sS]$') {
            Write-Host "${Blue}Instalación cancelada${NC}"
            exit 0
        }
    }
} catch {
    Write-Host "${Gray}uv no está instalado${NC}"
}

Write-Host ""

# Descargar e instalar usando el script oficial de PowerShell
Write-Host "${Blue}→ Descargando e instalando uv...${NC}"
Write-Host "${Gray}Ejecutando instalador oficial de uv...${NC}"
Write-Host ""

try {
    $installScript = Invoke-RestMethod https://astral.sh/uv/install.ps1
    if (-not $installScript) {
        throw "No se pudo descargar el script de instalación"
    }
    
    # Ejecutar el script de instalación
    Invoke-Expression $installScript
    
    Write-Host ""
    Write-Host "${Green}✓ Instalación completada${NC}"
} catch {
    Write-Host "${Red}✗ Error durante la instalación: $_${NC}"
    Write-Host ""
    Write-Host "${Yellow}Puedes intentar la instalación manual:${NC}"
    Write-Host "  ${Cyan}1. Con cargo: ${Green}cargo install uv${NC}"
    Write-Host "  ${Cyan}2. Con pip: ${Green}pip install uv${NC}"
    Write-Host "  ${Cyan}3. Descargar binario desde: ${Green}https://github.com/astral-sh/uv/releases${NC}"
    exit 1
}

Write-Host ""

# Actualizar PATH en la sesión actual
$uvPath = "$env:USERPROFILE\.cargo\bin"
if (Test-Path $uvPath) {
    $env:PATH = "$uvPath;$env:PATH"
    Write-Host "${Green}✓ PATH actualizado en la sesión actual${NC}"
}

Write-Host ""

# Verificar instalación
Write-Host "${Blue}→ Verificando instalación...${NC}"
Start-Sleep -Seconds 1

try {
    $uvVersion = & uv --version 2>&1
    Write-Host "${Green}✓ uv instalado correctamente: $uvVersion${NC}"
} catch {
    Write-Host "${Yellow}⚠ uv instalado pero no disponible en esta sesión${NC}"
    Write-Host "${Cyan}Reinicia PowerShell o abre una nueva ventana${NC}"
    Write-Host "${Gray}Ubicación: $uvPath${NC}"
}

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✨ ¡Instalación completada!${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Cyan}¿Qué es uv?${NC}"
Write-Host "  ${Gray}uv es un gestor de paquetes Python escrito en Rust${NC}"
Write-Host "  ${Gray}Es 10-100x más rápido que pip${NC}"
Write-Host "  ${Gray}Compatible con pip pero mucho más eficiente${NC}"
Write-Host ""
Write-Host "${Cyan}Comandos útiles de uv:${NC}"
Write-Host "  ${Green}uv pip install <package>${NC}      - Instalar paquete (como pip)"
Write-Host "  ${Green}uv venv${NC}                        - Crear entorno virtual"
Write-Host "  ${Green}uv pip sync requirements.txt${NC}   - Sincronizar dependencias"
Write-Host "  ${Green}uv pip compile pyproject.toml${NC}  - Generar requirements.txt"
Write-Host ""
Write-Host "${Cyan}Ejemplos:${NC}"
Write-Host "  ${Gray}# Crear y activar entorno virtual${NC}"
Write-Host "  ${Green}uv venv${NC}"
Write-Host "  ${Green}.venv\Scripts\Activate.ps1${NC}"
Write-Host ""
Write-Host "  ${Gray}# Instalar paquetes rápidamente${NC}"
Write-Host "  ${Green}uv pip install fastapi uvicorn pandas${NC}"
Write-Host ""
Write-Host "${Green}🚀 uv está listo para acelerar tu desarrollo Python!${NC}"
Write-Host ""
