# Script de análisis de espacio en disco para Windows
# Muestra uso de unidades, carpetas y archivos grandes

$Green  = "`e[32m"
$Yellow = "`e[33m"
$Purple = "`e[35m"
$Cyan   = "`e[36m"
$Gray   = "`e[90m"
$Red    = "`e[31m"
$Bold   = "`e[1m"
$NC     = "`e[0m"

function Show-Header {
    param($Title, $Subtitle)
    Clear-Host
    Write-Host ""
    Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
    Write-Host "${Purple}║  $Title${NC}"
    Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
    Write-Host "${Gray}  $Subtitle${NC}"
    Write-Host ""
}

function Write-Progress-Msg { param($Msg); Write-Host "  ${Cyan}⏳${NC} $Msg" }
function Write-Success      { param($Msg); Write-Host "  ${Green}✓${NC} $Msg" }
function Write-Warning-Msg  { param($Msg); Write-Host "  ${Yellow}⚠${NC} $Msg" }
function Write-Error-Msg    { param($Msg); Write-Host "  ${Red}✗${NC} $Msg" }
function Write-Info         { param($Msg); Write-Host "  ${Cyan}ℹ${NC} $Msg" }

function Format-Size($bytes) {
    if (-not $bytes) { return "0 B" }
    if ($bytes -ge 1GB) { return "$([math]::Round($bytes/1GB, 2)) GB" }
    if ($bytes -ge 1MB) { return "$([math]::Round($bytes/1MB, 2)) MB" }
    if ($bytes -ge 1KB) { return "$([math]::Round($bytes/1KB, 2)) KB" }
    return "$bytes B"
}

function Show-Menu {
    Show-Header "Análisis de Espacio 💾" "Gestión de almacenamiento"
    Write-Host "  ${Cyan}Opciones disponibles:${NC}"
    Write-Host ""
    Write-Host "  ${Green}1.${NC} Ver espacio en unidades de disco"
    Write-Host "  ${Green}2.${NC} Top 10 carpetas más grandes (directorio actual)"
    Write-Host "  ${Green}3.${NC} Top 20 archivos más grandes (directorio actual)"
    Write-Host "  ${Green}4.${NC} Analizar carpeta específica"
    Write-Host "  ${Green}5.${NC} Buscar archivos grandes (>100MB)"
    Write-Host "  ${Green}6.${NC} Espacio usado por tipo de archivo"
    Write-Host "  ${Green}7.${NC} Análisis del directorio de usuario"
    Write-Host "  ${Green}8.${NC} Limpiar archivos temporales"
    Write-Host "  ${Green}0.${NC} Salir"
    Write-Host ""
}

function Show-DiskSpace {
    Write-Progress-Msg "Mostrando espacio en unidades de disco..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Espacio en unidades de disco:${NC}"
    Write-Host ""

    $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }

    foreach ($disk in $disks) {
        $totalGB   = [math]::Round($disk.Size / 1GB, 2)
        $freeGB    = [math]::Round($disk.FreeSpace / 1GB, 2)
        $usedGB    = [math]::Round($totalGB - $freeGB, 2)
        $usagePct  = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 1) } else { 0 }
        $barColor  = if ($usagePct -gt 90) { $Red } elseif ($usagePct -gt 70) { $Yellow } else { $Green }
        $barWidth  = 40
        $filled    = [math]::Round($usagePct / 100 * $barWidth)
        $bar       = ("█" * $filled) + ("░" * ($barWidth - $filled))

        Write-Host "  ${Cyan}$($disk.DeviceID)${NC}  Total: ${Green}$totalGB GB${NC}  Usado: ${barColor}$usedGB GB ($usagePct%)${NC}  Libre: ${Green}$freeGB GB${NC}"
        Write-Host "  ${barColor}[$bar]${NC}"
        Write-Host ""

        if ($usagePct -gt 90) {
            Write-Warning-Msg "⚠ Unidad $($disk.DeviceID) con uso >90%"
            Write-Host ""
        }
    }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-TopDirectories {
    Write-Progress-Msg "Analizando carpetas en directorio actual..."
    Write-Info "Esto puede tardar unos segundos..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Top 10 carpetas más grandes:${NC}"
    Write-Host ""

    Get-ChildItem -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{ Nombre = $_.Name; Bytes = $size; Tamaño = Format-Size $size }
        } |
        Sort-Object Bytes -Descending | Select-Object -First 10 |
        Format-Table -AutoSize `
            @{Label="Tamaño"; Expression={$_.Tamaño}; Width=12},
            @{Label="Carpeta"; Expression={$_.Nombre}}

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-TopFiles {
    Write-Progress-Msg "Buscando archivos grandes en directorio actual..."
    Write-Info "Esto puede tardar unos segundos..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Top 20 archivos más grandes:${NC}"
    Write-Host ""

    Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending | Select-Object -First 20 |
        Select-Object @{Label="Tamaño"; Expression={Format-Size $_.Length}}, FullName |
        Format-Table -AutoSize

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Analyze-Directory {
    Write-Host ""
    $dirPath = Read-Host "${Cyan}Introduce la ruta de la carpeta (Enter para actual)${NC}"
    if (-not $dirPath) { $dirPath = (Get-Location).Path }

    if (-not (Test-Path $dirPath -PathType Container)) {
        Write-Error-Msg "La carpeta '$dirPath' no existe"
        return
    }

    Write-Host ""
    Write-Progress-Msg "Analizando $dirPath..."
    Write-Host ""

    $allItems  = Get-ChildItem $dirPath -Recurse -ErrorAction SilentlyContinue
    $files     = $allItems | Where-Object { -not $_.PSIsContainer }
    $dirs      = $allItems | Where-Object {   $_.PSIsContainer }
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum

    Write-Host "  ${Green}Tamaño total:${NC} $(Format-Size $totalSize)"
    Write-Host "  ${Cyan}Archivos:${NC}     $($files.Count)"
    Write-Host "  ${Cyan}Carpetas:${NC}     $($dirs.Count)"
    Write-Host ""
    Write-Host "  ${Bold}Top 5 subcarpetas:${NC}"

    Get-ChildItem $dirPath -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{ Nombre = $_.Name; Bytes = $size; Tamaño = Format-Size $size }
        } |
        Sort-Object Bytes -Descending | Select-Object -First 5 |
        ForEach-Object { Write-Host "    ${Cyan}$($_.Tamaño.PadLeft(10))${NC}  $($_.Nombre)" }

    Write-Host ""
}

function Find-LargeFiles {
    Write-Host ""
    $minSizeMB = Read-Host "${Cyan}Tamaño mínimo en MB (Enter para 100MB)${NC}"
    if (-not $minSizeMB) { $minSizeMB = 100 }

    $searchDir = Read-Host "${Cyan}Directorio de búsqueda (Enter para directorio de usuario)${NC}"
    if (-not $searchDir) { $searchDir = $env:USERPROFILE }

    if (-not (Test-Path $searchDir)) {
        Write-Error-Msg "El directorio '$searchDir' no existe"
        return
    }

    Write-Host ""
    Write-Progress-Msg "Buscando archivos >${minSizeMB}MB en $searchDir..."
    Write-Info "Esto puede tardar varios minutos..."
    Write-Host ""

    $minBytes = [long]$minSizeMB * 1MB

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    Get-ChildItem $searchDir -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -gt $minBytes } |
        Sort-Object Length -Descending | Select-Object -First 30 |
        Select-Object @{Label="Tamaño"; Expression={Format-Size $_.Length}}, FullName |
        Format-Table -AutoSize

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Show-SpaceByType {
    Write-Host ""
    Write-Progress-Msg "Analizando espacio por tipo de archivo..."
    Write-Info "Esto puede tardar unos segundos..."
    Write-Host ""
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host "${Bold}Espacio usado por extensión (directorio actual):${NC}"
    Write-Host ""

    Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension } |
        Group-Object Extension |
        Select-Object `
            @{Label="Extensión";    Expression={$_.Name}},
            @{Label="Archivos";     Expression={$_.Count}},
            @{Label="Tamaño Total"; Expression={Format-Size ($_.Group | Measure-Object -Property Length -Sum).Sum}},
            @{Label="Bytes";        Expression={($_.Group | Measure-Object -Property Length -Sum).Sum}} |
        Sort-Object Bytes -Descending | Select-Object -First 10 |
        Format-Table -AutoSize Extensión, Archivos, "Tamaño Total"

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""
}

function Analyze-UserHome {
    Write-Progress-Msg "Analizando directorio de usuario ($env:USERPROFILE)..."
    Write-Info "Esto puede tardar unos segundos..."
    Write-Host ""

    $totalSize = (Get-ChildItem $env:USERPROFILE -Recurse -File -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum).Sum

    Write-Host "  ${Green}Tamaño total de usuario:${NC} $(Format-Size $totalSize)"
    Write-Host ""
    Write-Host "  ${Bold}Top 10 carpetas en usuario:${NC}"
    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"

    Get-ChildItem $env:USERPROFILE -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{ Nombre = $_.Name; Bytes = $size; Tamaño = Format-Size $size }
        } |
        Sort-Object Bytes -Descending | Select-Object -First 10 |
        ForEach-Object { Write-Host "    ${Cyan}$($_.Tamaño.PadLeft(10))${NC}  $($_.Nombre)" }

    Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
    Write-Host ""

    Write-Host "  ${Cyan}Carpetas comunes de caché/desarrollo:${NC}"
    @(
        @{Path="$env:LOCALAPPDATA\npm-cache";   Name="npm cache"},
        @{Path="$env:APPDATA\npm";              Name="npm global"},
        @{Path="$env:USERPROFILE\.nuget";       Name=".nuget"},
        @{Path="$env:USERPROFILE\.cargo";       Name=".cargo (Rust)"},
        @{Path="$env:LOCALAPPDATA\pip\Cache";   Name="pip cache"},
        @{Path="$env:LOCALAPPDATA\Temp";        Name="Temp (usuario)"}
    ) | ForEach-Object {
        if (Test-Path $_.Path) {
            $size = (Get-ChildItem $_.Path -Recurse -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            Write-Host "    $($_.Name): ${Yellow}$(Format-Size $size)${NC}"
        }
    }
    Write-Host ""
}

function Clear-TempFiles {
    Write-Host ""
    Write-Warning-Msg "Esta opción limpiará archivos temporales del sistema"
    Write-Host ""

    $confirm = Read-Host "${Yellow}¿Deseas continuar? (s/N)${NC}"
    if ($confirm -notmatch "^[sS]$") { Write-Info "Operación cancelada"; return }

    Write-Host ""
    Write-Progress-Msg "Limpiando archivos temporales..."
    Write-Host ""

    $totalFreed = [long]0

    @($env:TEMP, "$env:LOCALAPPDATA\Temp", "C:\Windows\Temp") | ForEach-Object {
        if (Test-Path $_) {
            $before = (Get-ChildItem $_ -Recurse -ErrorAction SilentlyContinue |
                       Measure-Object -Property Length -Sum).Sum
            Write-Info "Limpiando $_..."
            Get-ChildItem $_ -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $after = (Get-ChildItem $_ -Recurse -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum).Sum
            $freed = $before - $after
            $totalFreed += $freed
            Write-Host "    Liberado: ${Green}$(Format-Size $freed)${NC}"
        }
    }

    Write-Host ""
    Write-Success "Limpieza completada. Total liberado: $(Format-Size $totalFreed)"
    Write-Host ""
}

# =========================
#  Main Loop
# =========================

while ($true) {
    Show-Menu
    $option = Read-Host "${Yellow}Selecciona una opción${NC}"

    switch ($option) {
        "1" { Show-DiskSpace }
        "2" { Show-TopDirectories }
        "3" { Show-TopFiles }
        "4" { Analyze-Directory }
        "5" { Find-LargeFiles }
        "6" { Show-SpaceByType }
        "7" { Analyze-UserHome }
        "8" { Clear-TempFiles }
        "0" { Write-Host ""; Write-Success "¡Hasta luego!"; exit 0 }
        default { Write-Host ""; Write-Error-Msg "Opción inválida"; Write-Host "" }
    }

    Read-Host "${Cyan}Presiona Enter para continuar...${NC}" | Out-Null
}
