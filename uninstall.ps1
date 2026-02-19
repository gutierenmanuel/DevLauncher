# uninstall.ps1 — Elimina la configuración instalada por install.ps1
# Remueve el bloque "# Scripts Development Launcher" del perfil de PowerShell.

$Green  = "`e[32m"
$Yellow = "`e[33m"
$Cyan   = "`e[36m"
$Purple = "`e[35m"
$NC     = "`e[0m"

Write-Host "${Purple}╔════════════════════════════════════════════════════════════╗${NC}"
Write-Host "${Purple}║   Desinstalador de Scripts de Desarrollo                  ║${NC}"
Write-Host "${Purple}╚════════════════════════════════════════════════════════════╝${NC}"
Write-Host ""

# Detectar perfil
$ProfilePath = $PROFILE.CurrentUserAllHosts
if (-not $ProfilePath) { $ProfilePath = $PROFILE }

Write-Host "${Cyan}→ Perfil de PowerShell: $ProfilePath${NC}"
Write-Host ""

if (-not (Test-Path $ProfilePath)) {
    Write-Host "${Yellow}⚠ No existe el archivo de perfil. Nada que desinstalar.${NC}"
    Write-Host ""
    exit 0
}

$content = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue

if (-not ($content -match '# Scripts Development Launcher')) {
    Write-Host "${Yellow}⚠ No se encontró ninguna instalación previa en el perfil.${NC}"
    Write-Host ""
    exit 0
}

# Mostrar el bloque a eliminar
Write-Host "${Yellow}⚠ Se encontró la siguiente configuración instalada:${NC}"
Write-Host ""
$inBlock = $false
foreach ($line in (Get-Content -Path $ProfilePath)) {
    if ($line -match '# Scripts Development Launcher') { $inBlock = $true }
    if ($inBlock) { Write-Host "  $line" }
    if ($line -match '# End Scripts Development Launcher') { $inBlock = $false }
}
Write-Host ""

$response = Read-Host "¿Deseas eliminarla? (s/n)"
if ($response -notmatch '^[sS]$') {
    Write-Host "${Yellow}Desinstalación cancelada.${NC}"
    exit 0
}

Write-Host ""
Write-Host "${Cyan}→ Eliminando configuración...${NC}"

$lines    = Get-Content -Path $ProfilePath
$newLines = [System.Collections.Generic.List[string]]::new()
$skip     = $false
foreach ($line in $lines) {
    if ($line -match '# Scripts Development Launcher') { $skip = $true; continue }
    if ($skip -and $line -match '# End Scripts Development Launcher') { $skip = $false; continue }
    if (-not $skip) { $newLines.Add($line) }
}

# Quitar líneas en blanco extra al final
while ($newLines.Count -gt 0 -and $newLines[-1].Trim() -eq '') {
    $newLines.RemoveAt($newLines.Count - 1)
}

$newLines | Set-Content -Path $ProfilePath -Encoding UTF8

Write-Host "${Green}✓ Configuración eliminada de $ProfilePath${NC}"
Write-Host ""
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host "${Green}✨ Desinstalación completada${NC}"
Write-Host "${Purple}════════════════════════════════════════════════════════════${NC}"
Write-Host ""
Write-Host "${Cyan}Para aplicar los cambios, ejecuta:${NC}"
Write-Host "   ${Yellow}. `$PROFILE${NC}"
Write-Host ""
Write-Host "${Cyan}Si también quieres eliminar los scripts del sistema,${NC}"
Write-Host "${Cyan}usa el ejecutable: ${Yellow}.\installer.exe${NC} y elige Desinstalar."
Write-Host ""
