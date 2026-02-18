# Script auxiliar para crear dev.ps1 en la raíz del proyecto
# Ejecuta este script desde el directorio que contiene la carpeta "frontend"

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$NC = "`e[0m"

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║          Crear script dev.ps1 🚀                           ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Verificar que existe la carpeta frontend
if (-not (Test-Path "frontend")) {
    Write-Host "${Red}✗ No se encuentra la carpeta 'frontend'${NC}"
    Write-Host "${Yellow}Ejecuta este script desde el directorio que contiene la carpeta 'frontend'${NC}"
    Write-Host ""
    Write-Host "${Blue}Ubicación actual: $(Get-Location)${NC}"
    exit 1
}

Write-Host "${Green}✓ Carpeta frontend encontrada${NC}"
Write-Host ""

# Verificar si ya existe dev.ps1
if (Test-Path "dev.ps1") {
    Write-Host "${Yellow}⚠ El archivo dev.ps1 ya existe${NC}"
    $response = Read-Host "¿Deseas sobrescribirlo? (s/n)"
    if ($response -notmatch '^[sS]$') {
        Write-Host "${Blue}Operación cancelada${NC}"
        exit 0
    }
}

# Crear dev.ps1
$devPs1 = @'
# Script de desarrollo para proyecto frontend
# Inicia el servidor de desarrollo con Vite

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$NC = "`e[0m"

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║   Frontend Development Server 🚀                          ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "frontend")) {
    Write-Host "${Red}✗ No se encuentra el directorio 'frontend'${NC}"
    Write-Host "${Yellow}  Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
}

Set-Location frontend

# Verificar que pnpm esté instalado
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    Write-Host "${Red}✗ pnpm no está instalado${NC}"
    Write-Host "${Yellow}  Instálalo con: npm install -g pnpm${NC}"
    exit 1
}

Write-Host "${Green}✓ Directorio frontend encontrado${NC}"
Write-Host "${Green}✓ pnpm instalado${NC}"
Write-Host ""

# Verificar dependencias
if (-not (Test-Path "node_modules")) {
    Write-Host "${Blue}→ Instalando dependencias...${NC}"
    & pnpm install
    Write-Host ""
}

Write-Host "${Blue}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Blue}  Iniciando servidor de desarrollo...${NC}"
Write-Host "${Blue}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Green}🔥 Hot-Reload activado${NC}"
Write-Host "${Green}📦 Stack: React + Vite + TypeScript + Tailwind + shadcn/ui${NC}"
Write-Host ""
Write-Host "${Yellow}→ URL: http://localhost:5173${NC}"
Write-Host ""
Write-Host "${Purple}Presiona Ctrl+C para detener${NC}"
Write-Host ""

# Iniciar Vite
& pnpm dev
'@

$devPs1 | Out-File -FilePath "dev.ps1" -Encoding UTF8

Write-Host "${Green}✓ Script dev.ps1 creado exitosamente${NC}"
Write-Host ""
Write-Host "${Blue}📁 Ubicación: $(Get-Location)\dev.ps1${NC}"
Write-Host ""
Write-Host "${Cyan}Para usar:${NC}"
Write-Host "  ${Green}.\dev.ps1${NC}  - Iniciar servidor de desarrollo"
Write-Host ""
