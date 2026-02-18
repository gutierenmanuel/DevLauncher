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
$StaticDir = Join-Path $ScriptRoot "static"

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
    
    # Cargar ASCII art desde archivo
    $asciiFile = Join-Path $StaticDir "asciiart.txt"
    if (Test-Path $asciiFile) {
        $asciiLines = Get-Content -Path $asciiFile
        foreach ($line in $asciiLines) {
            if ($line -match "Dev.*Launcher") {
                Write-Host $line -ForegroundColor Cyan
            } else {
                Write-Host $line -ForegroundColor Magenta
            }
        }
    } else {
        # Fallback si no existe el archivo
        Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
        Write-Host "${Purple}║  🚀 Lanzador Universal de Scripts                         ║${NC}"
        Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
    }
    
    Write-Host ""
}

# Menú de categorías
function Show-CategoryMenu {
    param([string]$Platform)
    
    Show-Header -Breadcrumb @("Inicio")
    
    Write-Host "${DimGray}→ Escaneando categorías...${NC}"
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
        Write-Host "${Red}✗ No se encontraron categorías${NC}"
        return
    }
    
    # Box superior
    Write-Host "${Cyan}$BoxTL$($BoxH * 58)$BoxTR${NC}"
    Write-Host "${Cyan}$BoxV${NC} ${Yellow}${Bold}Selecciona una categoría${NC}$(' ' * 31)${Cyan}$BoxV${NC}"
    Write-Host "${Cyan}$BoxBL$($BoxH * 58)$BoxBR${NC}"
    Write-Host ""
    
    $i = 1
    foreach ($cat in $validCategories) {
        Write-Host "  ${Cyan}${Bold}[$i]${NC} $($cat.Icon)  ${Bold}$($cat.Name)${NC}"
        Write-Host "      ${DimGray}$($BoxSep * 2)${NC} ${Gray}$($cat.Description)${NC}"
        Write-Host "      ${DimGray}$($BoxSep * 2)${NC} ${DimGray}$($cat.Count) script$(if($cat.Count -ne 1){'s'})${NC}"
        if ($i -lt $validCategories.Count) {
            Write-Host ""
        }
        $i++
    }
    
    Write-Host ""
    Write-Host "${DimGray}$($BoxSep * 60)${NC}"
    Write-Host "  ${Cyan}${Bold}[0]${NC} ${Red}Salir${NC}"
    Write-Host ""
    
    Write-Host -NoNewline "${Yellow}▶${NC} Opción: "
    $choice = Read-Host
    
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $validCategories.Count) {
        $selectedCategory = $validCategories[[int]$choice - 1].Name
        Show-ScriptMenu -Platform $Platform -Category $selectedCategory
    } elseif ($choice -eq "0") {
        Write-Host ""
        Write-Host "${Yellow}¡Hasta luego!${NC}"
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "${Red}✗ Opción inválida${NC}"
        Start-Sleep -Seconds 1
        Show-CategoryMenu -Platform $Platform
    }
}

# Menú de scripts dentro de una categoría
function Show-ScriptMenu {
    param([string]$Platform, [string]$Category)
    
    Show-Header -Breadcrumb @("Inicio", $Category)
    
    Write-Host ""
    $icon = Get-CategoryIcon -Category $Category
    
    $scripts = @(Get-ScriptsInCategory -Platform $Platform -Category $Category)
    
    if ($scripts.Count -eq 0) {
        Write-Host "${Red}✗ No se encontraron scripts en esta categoría${NC}"
        Start-Sleep -Seconds 2
        Show-CategoryMenu -Platform $Platform
        return
    }
    
    # Box superior
    Write-Host "${Cyan}$BoxTL$($BoxH * 58)$BoxTR${NC}"
    Write-Host "${Cyan}$BoxV${NC} $icon  ${Yellow}${Bold}$Category${NC}$(' ' * (50 - $Category.Length))${Cyan}$BoxV${NC}"
    Write-Host "${Cyan}$BoxML$($BoxH * 58)$BoxMR${NC}"
    Write-Host "${Cyan}$BoxV${NC} ${DimGray}$($scripts.Count) script$(if($scripts.Count -ne 1){'s'}) disponible$(if($scripts.Count -ne 1){'s'})${NC}$(' ' * (32 - $scripts.Count.ToString().Length))${Cyan}$BoxV${NC}"
    Write-Host "${Cyan}$BoxBL$($BoxH * 58)$BoxBR${NC}"
    Write-Host ""
    
    $i = 1
    foreach ($script in $scripts) {
        $description = Get-ScriptDescription -ScriptPath $script.FullName
        Write-Host "  ${Cyan}${Bold}[$i]${NC} ${Bold}$($script.Name)${NC}"
        if ($description) {
            Write-Host "      ${DimGray}$($BoxSep * 2)${NC} ${Gray}$description${NC}"
        }
        if ($i -lt $scripts.Count) {
            Write-Host ""
        }
        $i++
    }
    
    Write-Host ""
    Write-Host "${DimGray}$($BoxSep * 60)${NC}"
    Write-Host "  ${Cyan}${Bold}[.]${NC} ${Yellow}Volver atrás${NC}"
    Write-Host "  ${Cyan}${Bold}[0]${NC} ${Red}Salir${NC}"
    Write-Host ""
    
    Write-Host -NoNewline "${Yellow}▶${NC} Opción: "
    $choice = Read-Host
    
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $scripts.Count) {
        $selectedScript = $scripts[[int]$choice - 1]
        Clear-Screen
        Invoke-Script -ScriptPath $selectedScript.FullName
        
        Write-Host ""
        Write-Host -NoNewline "${Yellow}▶${NC} ¿Ejecutar otro script? ${DimGray}(s/N)${NC}: "
        $response = Read-Host
        if ($response -match '^[sS]$') {
            Show-ScriptMenu -Platform $Platform -Category $Category
        } else {
            Show-CategoryMenu -Platform $Platform
        }
    } elseif ($choice -eq ".") {
        Show-CategoryMenu -Platform $Platform
    } elseif ($choice -eq "0") {
        Write-Host ""
        Write-Host "${Yellow}¡Hasta luego!${NC}"
        Write-Host ""
    } else {
        Write-Host ""
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
    Write-Host "${Cyan}$BoxTL$($BoxH * 58)$BoxTR${NC}"
    Write-Host "${Cyan}$BoxV${NC} ${Magenta}⚡ Ejecutando:${NC} ${Bold}$scriptName${NC}$(' ' * (43 - $scriptName.Length))${Cyan}$BoxV${NC}"
    Write-Host "${Cyan}$BoxBL$($BoxH * 58)$BoxBR${NC}"
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
    if ($exitCode -eq 0 -or $null -eq $exitCode) {
        Write-Host "${Green}$BoxTL$($BoxH * 58)$BoxTR${NC}"
        Write-Host "${Green}$BoxV${NC} ${Green}✓ Script completado exitosamente${NC}$(' ' * 24)${Green}$BoxV${NC}"
        Write-Host "${Green}$BoxBL$($BoxH * 58)$BoxBR${NC}"
    } else {
        Write-Host "${Red}$BoxTL$($BoxH * 58)$BoxTR${NC}"
        Write-Host "${Red}$BoxV${NC} ${Red}✗ El script falló con código de salida: $exitCode${NC}$(' ' * (19 - $exitCode.ToString().Length))${Red}$BoxV${NC}"
        Write-Host "${Red}$BoxBL$($BoxH * 58)$BoxBR${NC}"
    }
}

# Listar todos los scripts (modo plano)
function Show-AllScripts {
    param([string]$Platform)
    
    Show-Header -Breadcrumb @("Inicio", "Lista completa")
    
    Write-Host "${DimGray}→ Plataforma: $Platform${NC}"
    Write-Host ""
    
    $categories = @(Get-Categories -Platform $Platform)
    $totalScripts = 0
    $validCategoryCount = 0
    
    foreach ($category in $categories) {
        $count = Count-ScriptsInCategory -Platform $Platform -Category $category
        if ($count -gt 0) {
            Write-Host ""
            $icon = Get-CategoryIcon -Category $category
            $desc = Get-CategoryDescription -Category $category
            
            Write-Host "${Cyan}$BoxTL$($BoxH * 58)$BoxTR${NC}"
            Write-Host "${Cyan}$BoxV${NC} $icon  ${Yellow}${Bold}$category${NC}$(' ' * (50 - $category.Length))${Cyan}$BoxV${NC}"
            Write-Host "${Cyan}$BoxBL$($BoxH * 58)$BoxBR${NC}"
            Write-Host ""
            
            $scripts = Get-ScriptsInCategory -Platform $Platform -Category $category
            foreach ($script in $scripts) {
                $description = Get-ScriptDescription -ScriptPath $script.FullName
                Write-Host "  ${Cyan}•${NC} ${Bold}$($script.Name)${NC}"
                if ($description) {
                    Write-Host "    ${DimGray}$($BoxSep * 2)${NC} ${Gray}$description${NC}"
                }
            }
            
            $totalScripts += $count
            $validCategoryCount++
        }
    }
    
    Write-Host ""
    Write-Host "${DimGray}$($BoxSep * 60)${NC}"
    Write-Host "${DimGray}Total: $totalScripts scripts en $validCategoryCount categorías${NC}"
    Write-Host ""
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

function Main {
    param([string[]]$Arguments)
    
    Show-Header
    
    # Detectar plataforma - Windows siempre usa carpeta 'win'
    $platform = "win"
    
    Write-Host "${Gray}Plataforma: Windows | Directorio: $ScriptsDir\$platform${NC}"
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
