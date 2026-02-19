# Script para instalar Volta en Windows
# Volta es un gestor de versiones de Node.js rápido y confiable

# Auto-elevar a administrador si no se tienen los permisos necesarios
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Se requieren permisos de administrador para instalar Volta." -ForegroundColor Yellow
    Write-Host "Solicitando elevacion..." -ForegroundColor Yellow
    $psExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    Start-Process $psExe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
    exit
}

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

Show-Header "Instalador de Volta ⚡" "Gestor de versiones de Node.js"

# Verificar si Volta ya está instalado
Write-Host "${Blue}→ Verificando instalación existente...${NC}"
$voltaExists = $null
try {
    $voltaExists = Get-Command volta -ErrorAction SilentlyContinue
    if ($voltaExists) {
        Write-Host "${Yellow}⚠ Volta ya está instalado${NC}"
        $voltaVersion = & volta --version 2>&1
        Write-Host "${Green}Versión: $voltaVersion${NC}"
        Write-Host ""
        $response = Read-Host "¿Deseas reinstalar Volta? (s/n)"
        if ($response -notmatch '^[sS]$') {
            Write-Host "${Blue}Instalación cancelada${NC}"
            exit 0
        }
    }
} catch {
    Write-Host "${Gray}Volta no está instalado${NC}"
}

Write-Host ""

# URL del instalador de Volta para Windows
$voltaInstallerUrl = "https://github.com/volta-cli/volta/releases/latest/download/volta-windows-x86_64.msi"
$installerPath = "$env:TEMP\volta-installer.msi"

Write-Host "${Blue}→ Descargando Volta...${NC}"
Write-Host "${Gray}URL: $voltaInstallerUrl${NC}"
Write-Host ""

try {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $voltaInstallerUrl -OutFile $installerPath -ErrorAction Stop
    Write-Host "${Green}✓ Descarga completada${NC}"
} catch {
    Write-Host "${Red}✗ Error al descargar Volta: $_${NC}"
    Write-Host ""
    Write-Host "${Yellow}Puedes descargarlo manualmente desde:${NC}"
    Write-Host "  https://volta.sh"
    exit 1
}

Write-Host ""

# Instalar Volta
Write-Host "${Blue}→ Instalando Volta...${NC}"
Write-Host "${Yellow}Se abrirá el instalador de Windows...${NC}"
Write-Host ""

$logFile = "$env:TEMP\volta-install.log"
try {
    $process = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i", $installerPath, "/passive", "/norestart", "/log", $logFile `
        -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "${Green}✓ Volta instalado correctamente${NC}"
    } else {
        Write-Host "${Red}✗ La instalación falló con código: $($process.ExitCode)${NC}"
        if (Test-Path $logFile) {
            Write-Host "${Yellow}  Ultimas lineas del log:${NC}"
            Get-Content $logFile | Select-Object -Last 15 | ForEach-Object { Write-Host "    $_" }
        }
        exit 1
    }
} catch {
    Write-Host "${Red}✗ Error durante la instalación: $_${NC}"
    exit 1
} finally {
    Remove-Item $logFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""

# Limpiar archivo de instalación
Write-Host "${Blue}→ Limpiando archivos temporales...${NC}"
Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
Write-Host "${Green}✓ Limpieza completada${NC}"

Write-Host ""

# Actualizar PATH en la sesión actual (leer desde el registro para capturar lo que instaló el MSI)
$env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:VOLTA_HOME = "$env:LOCALAPPDATA\Volta"

Write-Host "${Green}✓ Variables de entorno configuradas${NC}"

Write-Host ""

# Verificar instalación
Write-Host "${Blue}→ Verificando instalación...${NC}"
Start-Sleep -Seconds 2

try {
    $voltaVersion = & volta --version 2>&1
    Write-Host "${Green}✓ Volta instalado: $voltaVersion${NC}"
} catch {
    Write-Host "${Yellow}⚠ Volta instalado pero no disponible en esta sesión${NC}"
    Write-Host "${Cyan}Reinicia PowerShell o abre una nueva ventana${NC}"
}

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✨ ¡Instalación completada!${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Cyan}Próximos pasos:${NC}"
Write-Host "  ${Gray}1. Reinicia PowerShell${NC}"
Write-Host "  ${Gray}2. Instala Node.js: ${Green}volta install node${NC}"
Write-Host "  ${Gray}3. Instala pnpm: ${Green}volta install pnpm${NC}"
Write-Host ""
Write-Host "${Cyan}Comandos útiles de Volta:${NC}"
Write-Host "  ${Green}volta install node@20${NC}     - Instalar Node.js versión 20"
Write-Host "  ${Green}volta install node@latest${NC} - Instalar última versión de Node"
Write-Host "  ${Green}volta install npm${NC}         - Instalar npm"
Write-Host "  ${Green}volta install yarn${NC}        - Instalar yarn"
Write-Host "  ${Green}volta list${NC}                - Ver herramientas instaladas"
Write-Host ""
Write-Host "${Green}🚀 Volta está listo para gestionar tus versiones de Node!${NC}"
Write-Host ""
