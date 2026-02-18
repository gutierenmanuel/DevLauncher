# Script para instalar Python 3.12 en Windows
# Descarga e instala Python 3.12 desde python.org

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

Show-Header "Instalador de Python 3.12 🐍" "Última versión estable de Python"

# Verificar si Python 3.12 ya está instalado
Write-Host "${Blue}→ Verificando instalación existente...${NC}"
$pythonVersion = $null
try {
    $pythonVersion = & python --version 2>&1
    if ($pythonVersion -match "3\.12") {
        Write-Host "${Yellow}⚠ Python 3.12 ya está instalado${NC}"
        Write-Host "${Green}Versión: $pythonVersion${NC}"
        Write-Host ""
        $response = Read-Host "¿Deseas reinstalar? (s/n)"
        if ($response -notmatch '^[sS]$') {
            Write-Host "${Blue}Instalación cancelada${NC}"
            exit 0
        }
    }
} catch {
    Write-Host "${Gray}Python no está instalado${NC}"
}

Write-Host ""

# URL de descarga - Python 3.12 (actualizar según última versión)
$pythonVersion = "3.12.8"
$pythonUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-amd64.exe"
$installerPath = "$env:TEMP\python-$pythonVersion-installer.exe"

Write-Host "${Blue}→ Descargando Python $pythonVersion...${NC}"
Write-Host "${Gray}URL: $pythonUrl${NC}"
Write-Host "${Gray}Destino: $installerPath${NC}"
Write-Host ""

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -ErrorAction Stop
    Write-Host "${Green}✓ Descarga completada${NC}"
} catch {
    Write-Host "${Red}✗ Error al descargar Python: $_${NC}"
    Write-Host ""
    Write-Host "${Yellow}Puedes descargarlo manualmente desde:${NC}"
    Write-Host "  https://www.python.org/downloads/"
    exit 1
}

Write-Host ""

# Instalar Python
Write-Host "${Blue}→ Instalando Python $pythonVersion...${NC}"
Write-Host "${Yellow}Configuración:${NC}"
Write-Host "  • Instalación para todos los usuarios"
Write-Host "  • Agregar Python al PATH"
Write-Host "  • Incluir pip, tcl/tk, y documentación"
Write-Host "  • Precompilar biblioteca estándar"
Write-Host ""

$installArgs = @(
    "/quiet",
    "InstallAllUsers=1",
    "PrependPath=1",
    "Include_pip=1",
    "Include_tcltk=1",
    "Include_doc=1",
    "Include_test=0",
    "SimpleInstall=1",
    "CompileAll=1"
)

try {
    $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "${Green}✓ Python instalado correctamente${NC}"
    } else {
        Write-Host "${Red}✗ La instalación falló con código: $($process.ExitCode)${NC}"
        exit 1
    }
} catch {
    Write-Host "${Red}✗ Error durante la instalación: $_${NC}"
    exit 1
}

Write-Host ""

# Limpiar archivo de instalación
Write-Host "${Blue}→ Limpiando archivos temporales...${NC}"
Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
Write-Host "${Green}✓ Limpieza completada${NC}"

Write-Host ""

# Actualizar PATH en la sesión actual
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

# Verificar instalación
Write-Host "${Blue}→ Verificando instalación...${NC}"
Start-Sleep -Seconds 2

try {
    $installedVersion = & python --version 2>&1
    Write-Host "${Green}✓ Python instalado: $installedVersion${NC}"
    
    $pipVersion = & python -m pip --version 2>&1
    Write-Host "${Green}✓ pip disponible: $pipVersion${NC}"
} catch {
    Write-Host "${Yellow}⚠ Python instalado pero no disponible en esta sesión${NC}"
    Write-Host "${Cyan}Reinicia PowerShell o abre una nueva ventana${NC}"
}

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✨ ¡Instalación completada!${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Cyan}Comandos útiles:${NC}"
Write-Host "  ${Green}python --version${NC}           - Ver versión instalada"
Write-Host "  ${Green}python -m venv venv${NC}        - Crear entorno virtual"
Write-Host "  ${Green}python -m pip install <pkg>${NC} - Instalar paquetes"
Write-Host ""
Write-Host "${Cyan}Crear un proyecto con Python:${NC}"
Write-Host "  ${Gray}# Crear entorno virtual${NC}"
Write-Host "  ${Green}python -m venv .venv${NC}"
Write-Host ""
Write-Host "  ${Gray}# Activar entorno${NC}"
Write-Host "  ${Green}.venv\Scripts\Activate.ps1${NC}"
Write-Host ""
Write-Host "  ${Gray}# Instalar paquetes${NC}"
Write-Host "  ${Green}pip install requests pandas${NC}"
Write-Host ""
Write-Host "${Yellow}💡 Tip: Considera usar ${Cyan}uv${NC} para gestión de paquetes más rápida${NC}"
Write-Host ""
Write-Host "${Green}🚀 Python está listo para usar!${NC}"
Write-Host ""
