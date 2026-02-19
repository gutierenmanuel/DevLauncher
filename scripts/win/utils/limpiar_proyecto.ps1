# Script de utilidades - Limpieza de directorios temporales y caché
# Limpia node_modules, __pycache__, .venv, build, dist, etc.

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$Cyan = "`e[36m"
$Gray = "`e[90m"
$NC = "`e[0m"

Write-Host ""
Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║          Limpiador de Proyecto 🧹                          ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

$currentDir = Get-Location
Write-Host "${Blue}→ Directorio actual: ${Cyan}$currentDir${NC}"
Write-Host ""

# Directorios y archivos a limpiar
$targets = @{
    "node_modules" = "Dependencias de Node.js"
    "__pycache__" = "Caché de Python"
    ".pytest_cache" = "Caché de pytest"
    ".venv" = "Entorno virtual de Python"
    "venv" = "Entorno virtual de Python"
    "dist" = "Archivos de distribución"
    "build" = "Archivos de compilación"
    ".next" = "Caché de Next.js"
    ".nuxt" = "Caché de Nuxt.js"
    "target" = "Target de Rust/Maven"
    "bin" = "Binarios compilados"
    "obj" = "Objetos de .NET"
    ".turbo" = "Caché de Turborepo"
    "*.log" = "Archivos de log"
    "*.tmp" = "Archivos temporales"
}

Write-Host "${Yellow}Se buscarán y eliminarán los siguientes elementos:${NC}"
Write-Host ""
foreach ($target in $targets.Keys) {
    Write-Host "  ${Cyan}•${NC} ${Gray}$target${NC} - $($targets[$target])"
}
Write-Host ""

$response = Read-Host "${Yellow}¿Continuar con la limpieza? (s/n)${NC}"
if ($response -notmatch '^[sS]$') {
    Write-Host "${Blue}Operación cancelada${NC}"
    exit 0
}

Write-Host ""
Write-Host "${Blue}→ Buscando elementos a eliminar...${NC}"
Write-Host ""

$totalSize = 0
$itemsRemoved = 0

foreach ($target in $targets.Keys) {
    # Buscar directorios
    if ($target -notlike "*.*") {
        $items = Get-ChildItem -Path . -Directory -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $target }
        
        foreach ($item in $items) {
            try {
                $size = (Get-ChildItem -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                if ($size) {
                    $sizeMB = [math]::Round($size / 1MB, 2)
                    Write-Host "  ${Red}✗${NC} ${Gray}$($item.FullName)${NC} (${Yellow}$sizeMB MB${NC})"
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                    $totalSize += $size
                    $itemsRemoved++
                }
            } catch {
                Write-Host "  ${Yellow}⚠${NC} No se pudo eliminar: $($item.FullName)"
            }
        }
    }
    # Buscar archivos
    else {
        $items = Get-ChildItem -Path . -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $target }
        
        foreach ($item in $items) {
            try {
                $sizeMB = [math]::Round($item.Length / 1MB, 2)
                Write-Host "  ${Red}✗${NC} ${Gray}$($item.FullName)${NC} (${Yellow}$sizeMB MB${NC})"
                Remove-Item -Path $item.FullName -Force -ErrorAction Stop
                $totalSize += $item.Length
                $itemsRemoved++
            } catch {
                Write-Host "  ${Yellow}⚠${NC} No se pudo eliminar: $($item.FullName)"
            }
        }
    }
}

Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

if ($itemsRemoved -eq 0) {
    Write-Host "${Green}✓ No se encontraron elementos para limpiar${NC}"
} else {
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    $totalSizeGB = [math]::Round($totalSize / 1GB, 2)
    
    Write-Host "${Green}✓ Limpieza completada${NC}"
    Write-Host "  Elementos eliminados: ${Cyan}$itemsRemoved${NC}"
    if ($totalSizeGB -gt 1) {
        Write-Host "  Espacio liberado: ${Green}$totalSizeGB GB${NC}"
    } else {
        Write-Host "  Espacio liberado: ${Green}$totalSizeMB MB${NC}"
    }
}

Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Read-Host "Presiona Enter para volver al launcher..."
