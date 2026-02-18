# Lanzador Universal de Scripts de Desarrollo (Windows)
# Navegación jerárquica: Carpeta → Script

# Colores
$Green = "`e[32m"
$Blue = "`e[34m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Purple = "`e[35m"
$Cyan = "`e[36m"
$Gray = "`e[90m"
$Bold = "`e[1m"
$NC = "`e[0m"

# Obtener el directorio raíz del proyecto
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsDir = Join-Path $ScriptRoot "scripts"

# Cargar librería común si existe
$CommonLib = Join-Path $ScriptsDir "lib\common.ps1"
if (Test-Path $CommonLib) {
    . $CommonLib
}

# ==========================================
# FUNCIONES DEL LANZADOR
# ==========================================

# Obtener icono para cada categoría
function Get-CategoryIcon {
    param([string]$Category)
    
    switch ($Category) {
        "build" { "🏗️" }
        "dev" { "💻" }
        "inicializar_repos" { "🆕" }
        "instaladores" { "📦" }
        {$_ -in "utils","utilidades"} { "🔧" }
        default { "📁" }
    }
}

# Obtener descripción de categoría
function Get-CategoryDescription {
    param([string]$Category)
    
    switch ($Category) {
        "build" { "Scripts de compilación y construcción" }
        "dev" { "Scripts de desarrollo y servidor" }
        "inicializar_repos" { "Inicializadores de proyectos nuevos" }
        "instaladores" { "Instaladores de herramientas y dependencias" }
        {$_ -in "utils","utilidades"} { "Utilidades y herramientas varias" }
        default { "Scripts varios" }
    }
}

# Extraer descripción de un script
function Get-ScriptDescription {
    param([string]$ScriptPath)
    
    if (-not (Test-Path $ScriptPath)) {
        return "Sin descripción"
    }
    
    $lines = Get-Content -Path $ScriptPath -TotalCount 5 -ErrorAction SilentlyContinue
    $desc = $lines | Where-Object { $_ -match '^\s*#\s*(Script|Descripción|Description)' } | Select-Object -First 1
    
    if ($desc) {
        $desc = $desc -replace '^\s*#\s*', '' -replace 'Script\s*', '' -replace 'Descripción:\s*', '' -replace 'Description:\s*', ''
        return $desc.Trim()
    }
    
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
    return $filename -replace '_', ' '
}

# Listar categorías disponibles
function Get-Categories {
    param([string]$Platform)
    
    $scanDir = Join-Path $ScriptsDir $Platform
    if (-not (Test-Path $scanDir)) {
        return @()
    }
    
    Get-ChildItem -Path $scanDir -Directory | 
        Where-Object { $_.Name -ne 'lib' } |
        Sort-Object Name |
        ForEach-Object { $_.Name }
}

# Listar scripts en una categoría
function Get-ScriptsInCategory {
    param([string]$Platform, [string]$Category)
    
    $categoryDir = Join-Path $ScriptsDir "$Platform\$Category"
    if (-not (Test-Path $categoryDir)) {
        return @()
    }
    
    if ($Platform -eq "linux") {
        Get-ChildItem -Path $categoryDir -Filter "*.sh" -File |
            Where-Object { $_.Name -notlike "example_*" } |
            Sort-Object Name
    } else {
        Get-ChildItem -Path $categoryDir -File |
            Where-Object { $_.Extension -in @('.ps1', '.bat') } |
            Sort-Object Name
    }
}

# Contar scripts en una categoría
function Count-ScriptsInCategory {
    param([string]$Platform, [string]$Category)
    
    return (Get-ScriptsInCategory -Platform $Platform -Category $Category | Measure-Object).Count
}

# Mostrar encabezado
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

# Menú de categorías
function Show-CategoryMenu {
    param([string]$Platform)
    
    Write-Host "${Blue}→ Escaneando categorías disponibles...${NC}"
    Write-Host ""
    
    $categories = @(Get-Categories -Platform $Platform)
    $validCategories = @()
    
    foreach ($category in $categories) {
        $count = Count-ScriptsInCategory -Platform $Platform -Category $category
        if ($count -gt 0) {
            $validCategories += @{
                Name = $category
                Count = $count
                Icon = Get-CategoryIcon -Category $category
                Description = Get-CategoryDescription -Category $category
            }
        }
    }
    
    if ($validCategories.Count -eq 0) {
        Write-Host "${Red}✗ No se encontraron categorías con scripts${NC}"
        return
    }
    
    Write-Host "${Green}✓ Encontradas $($validCategories.Count) categorías${NC}"
    Write-Host ""
    Write-Host "${Yellow}${Bold}Selecciona una categoría:${NC}"
    Write-Host ""
    
    $i = 1
    foreach ($cat in $validCategories) {
        Write-Host "${Cyan}$i)${NC} $($cat.Icon)  ${Bold}$($cat.Name)${NC}"
        Write-Host "   ${Gray}$($cat.Description) ($($cat.Count) scripts)${NC}"
        $i++
    }
    Write-Host "${Cyan}0)${NC} ${Red}← Salir${NC}"
    Write-Host ""
    
    $choice = Read-Host "Opción"
    
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $validCategories.Count) {
        $selectedCategory = $validCategories[[int]$choice - 1].Name
        Show-ScriptMenu -Platform $Platform -Category $selectedCategory
    } elseif ($choice -eq "0") {
        Write-Host "${Yellow}Cancelado${NC}"
    } else {
        Write-Host "${Red}✗ Opción inválida${NC}"
    }
}

# Menú de scripts dentro de una categoría
function Show-ScriptMenu {
    param([string]$Platform, [string]$Category)
    
    Write-Host ""
    $icon = Get-CategoryIcon -Category $Category
    Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
    $catPadded = "  $icon  $Category" + (" " * (55 - $Category.Length - $icon.Length))
    Write-Host "${Purple}║${NC}$catPadded${Purple}║${NC}"
    Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
    Write-Host ""
    
    $scripts = @(Get-ScriptsInCategory -Platform $Platform -Category $Category)
    
    if ($scripts.Count -eq 0) {
        Write-Host "${Red}✗ No se encontraron scripts en esta categoría${NC}"
        return
    }
    
    Write-Host "${Yellow}${Bold}Selecciona un script:${NC}"
    Write-Host ""
    
    $i = 1
    foreach ($script in $scripts) {
        $description = Get-ScriptDescription -ScriptPath $script.FullName
        Write-Host "${Cyan}$i)${NC} ${Bold}$($script.Name)${NC}"
        Write-Host "   ${Gray}$description${NC}"
        $i++
    }
    Write-Host "${Cyan}b)${NC} ${Yellow}← Volver a categorías${NC}"
    Write-Host "${Cyan}0)${NC} ${Red}← Salir${NC}"
    Write-Host ""
    
    $choice = Read-Host "Opción"
    
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $scripts.Count) {
        $selectedScript = $scripts[[int]$choice - 1]
        Invoke-Script -ScriptPath $selectedScript.FullName
        
        Write-Host ""
        $response = Read-Host "¿Ejecutar otro script? (s/n)"
        if ($response -match '^[sS]$') {
            Show-ScriptMenu -Platform $Platform -Category $Category
        } else {
            Show-CategoryMenu -Platform $Platform
        }
    } elseif ($choice -match '^[bB]$') {
        Show-CategoryMenu -Platform $Platform
    } elseif ($choice -eq "0") {
        Write-Host "${Yellow}Saliendo...${NC}"
    } else {
        Write-Host "${Red}✗ Opción inválida${NC}"
        Start-Sleep -Seconds 1
        Show-ScriptMenu -Platform $Platform -Category $Category
    }
}

# Ejecutar script seleccionado
function Invoke-Script {
    param([string]$ScriptPath)
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "${Red}✗ El script no existe: $ScriptPath${NC}"
        return
    }
    
    $scriptName = Split-Path -Leaf $ScriptPath
    
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Purple}  Ejecutando: ${Cyan}${Bold}$scriptName${NC}"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
    
    $extension = [System.IO.Path]::GetExtension($ScriptPath)
    
    try {
        if ($extension -eq '.ps1') {
            & $ScriptPath
            $exitCode = $LASTEXITCODE
        } elseif ($extension -eq '.bat') {
            & cmd.exe /c $ScriptPath
            $exitCode = $LASTEXITCODE
        } elseif ($extension -eq '.sh') {
            if (Get-Command bash -ErrorAction SilentlyContinue) {
                & bash $ScriptPath
                $exitCode = $LASTEXITCODE
            } else {
                Write-Host "${Red}✗ Bash no está disponible para ejecutar scripts .sh${NC}"
                $exitCode = 1
            }
        }
    } catch {
        Write-Host "${Red}✗ Error al ejecutar el script: $_${NC}"
        $exitCode = 1
    }
    
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    if ($exitCode -eq 0 -or $null -eq $exitCode) {
        Write-Host "${Green}✓ Script completado exitosamente${NC}"
    } else {
        Write-Host "${Red}✗ El script falló con código de salida: $exitCode${NC}"
    }
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
}

# Listar todos los scripts (modo plano)
function Show-AllScripts {
    param([string]$Platform)
    
    Show-Header "Scripts Disponibles" "Plataforma: $Platform"
    
    $categories = @(Get-Categories -Platform $Platform)
    
    foreach ($category in $categories) {
        $count = Count-ScriptsInCategory -Platform $Platform -Category $category
        if ($count -gt 0) {
            Write-Host ""
            $icon = Get-CategoryIcon -Category $category
            $desc = Get-CategoryDescription -Category $category
            Write-Host "${Purple}$icon  ${Bold}$category${NC}"
            Write-Host "${Gray}   $desc${NC}"
            Write-Host "${Gray}   $('─' * 58)${NC}"
            
            $scripts = Get-ScriptsInCategory -Platform $Platform -Category $category
            foreach ($script in $scripts) {
                $description = Get-ScriptDescription -ScriptPath $script.FullName
                Write-Host "   ${Green}•${NC} ${Cyan}$($script.Name)${NC}"
                Write-Host "     ${Gray}$description${NC}"
            }
        }
    }
    
    Write-Host ""
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

function Main {
    param([string[]]$Arguments)
    
    Show-Header "🚀 Lanzador Universal de Scripts" "Navegación jerárquica: Categoría → Script"
    
    # Detectar plataforma - Windows siempre usa carpeta 'win'
    $platform = "win"
    
    Write-Host "${Blue}→ Plataforma detectada: ${Bold}Windows ($platform)${NC}"
    Write-Host "${Gray}→ Directorio de scripts: $ScriptsDir\$platform${NC}"
    Write-Host ""
    
    # Parsear argumentos
    if ($Arguments.Count -eq 0) {
        Show-CategoryMenu -Platform $platform
    } elseif ($Arguments[0] -in "-l","--list") {
        Show-AllScripts -Platform $platform
    } elseif ($Arguments[0] -in "-h","--help") {
        Write-Host "Uso: .\launcher.ps1 [opciones]"
        Write-Host ""
        Write-Host "Opciones:"
        Write-Host "  (sin opciones)  Mostrar menú interactivo jerárquico"
        Write-Host "  -l, --list      Listar todos los scripts organizados"
        Write-Host "  -h, --help      Mostrar esta ayuda"
        Write-Host ""
        Write-Host "Navegación:"
        Write-Host "  1. Selecciona una categoría (build, dev, instaladores, etc.)"
        Write-Host "  2. Selecciona un script dentro de la categoría"
        Write-Host "  3. El script se ejecuta automáticamente"
        Write-Host ""
    } else {
        Write-Host "${Red}✗ Opción desconocida: $($Arguments[0])${NC}"
        Write-Host "Usa --help para ver las opciones disponibles"
    }
}

# Ejecutar
Main -Arguments $args
