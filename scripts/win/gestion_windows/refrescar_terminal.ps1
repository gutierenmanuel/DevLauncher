# Script: Refresca la terminal recargando el PATH y variables de entorno
# Recarga el perfil de PowerShell para actualizar PATH y alias

$host.UI.RawUI.WindowTitle = "Refrescando Terminal..."

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   Refrescar Terminal 🔄                                    ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Detectar perfil actual
$shellName = if ($PSVersionTable.PSEdition -eq "Core") { "PowerShell (pwsh)" } else { "Windows PowerShell" }
Write-Host "ℹ Shell detectada: $shellName" -ForegroundColor Cyan

# Mostrar PATH actual (resumido)
Write-Host ""
Write-Host "→ PATH actual (primeros 5 directorios):" -ForegroundColor Blue
$paths = $env:PATH -split ';'
$paths | Select-Object -First 5 | ForEach-Object {
    Write-Host "  → $_" -ForegroundColor Green
}
if ($paths.Count -gt 5) {
    Write-Host "  ... y $($paths.Count - 5) más" -ForegroundColor DarkGray
}
Write-Host ""

# Refrescar variables de entorno desde el registro (Windows)
Write-Host "→ Recargando variables de entorno del sistema..." -ForegroundColor Blue

# Leer PATH fresco del registro
$machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:PATH = "$userPath;$machinePath"

# Recargar otras variables de entorno comunes
$envVars = @("GOPATH", "GOROOT", "JAVA_HOME", "PYTHON_HOME", "NODE_PATH", "CARGO_HOME", "RUSTUP_HOME")
foreach ($var in $envVars) {
    $machineVal = [System.Environment]::GetEnvironmentVariable($var, "Machine")
    $userVal = [System.Environment]::GetEnvironmentVariable($var, "User")
    $val = if ($userVal) { $userVal } elseif ($machineVal) { $machineVal } else { $null }
    if ($val) {
        [System.Environment]::SetEnvironmentVariable($var, $val, "Process")
        Write-Host "  ✓ $var actualizado" -ForegroundColor Green
    }
}

Write-Host ""

# Recargar perfil de PowerShell si existe
$profilePath = $PROFILE
if (Test-Path $profilePath) {
    Write-Host "→ Recargando perfil: $profilePath" -ForegroundColor Blue
    try {
        . $profilePath
        Write-Host "  ✓ Perfil recargado correctamente" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Error al recargar perfil: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ No se encontró perfil en: $profilePath" -ForegroundColor Yellow
}

Write-Host ""

# Mostrar nuevo PATH (resumido)
Write-Host "→ PATH actualizado (primeros 5 directorios):" -ForegroundColor Blue
$newPaths = $env:PATH -split ';'
$newPaths | Select-Object -First 5 | ForEach-Object {
    Write-Host "  → $_" -ForegroundColor Green
}
if ($newPaths.Count -gt 5) {
    Write-Host "  ... y $($newPaths.Count - 5) más" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "✓ Terminal refrescada correctamente" -ForegroundColor Green
Write-Host ""
Read-Host "Pulsa Enter para continuar"
