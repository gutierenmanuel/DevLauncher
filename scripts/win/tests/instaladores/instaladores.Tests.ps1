#Requires -Modules Pester
<#
.SYNOPSIS
    Tests de validación para los scripts instaladores de Windows.
    Verifica estructura, sintaxis y patrones de seguridad SIN ejecutar las instalaciones.
#>

# ─── Datos disponibles en fase de discovery (antes de BeforeAll) ─────────────
$InstaladorDir = Join-Path $PSScriptRoot "..\..\..\scripts\win\instaladores"

$AllPS1 = @(
    "instalar_go.ps1",
    "instalar_nodejs.ps1",
    "instalar_pnpm.ps1",
    "instalar_python312.ps1",
    "instalar_uv.ps1",
    "instalar_volta.ps1",
    "instalar_wails.ps1"
)

# Scripts que instalan a nivel de sistema (necesitan admin)
$NeedAdmin = @(
    "instalar_go.ps1",
    "instalar_python312.ps1",
    "instalar_volta.ps1"
)

# Scripts que usan descarga + instalador temporal
$UsesTempDownload = @(
    "instalar_go.ps1",
    "instalar_python312.ps1",
    "instalar_volta.ps1"
)

# Scripts que deben refrescar PATH al final
$RefreshesPath = @(
    "instalar_go.ps1",
    "instalar_python312.ps1",
    "instalar_volta.ps1"
)

# Scripts que verifican la instalación al final
$VerifiesInstall = @(
    "instalar_go.ps1",
    "instalar_nodejs.ps1",
    "instalar_pnpm.ps1",
    "instalar_volta.ps1",
    "instalar_wails.ps1"
)

BeforeAll {
    $InstaladorDir = Join-Path $PSScriptRoot "..\..\..\scripts\win\instaladores"

    # ─── Helpers ────────────────────────────────────────────────────────────────

    function Get-ScriptAST {
        param([string]$Path)
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $Path, [ref]$tokens, [ref]$errors)
        return @{ AST = $ast; Errors = $errors; Tokens = $tokens }
    }

    function Get-ScriptContent {
        param([string]$ScriptName)
        Get-Content (Join-Path $InstaladorDir $ScriptName) -Raw
    }

    function Script-Contains {
        param([string]$ScriptName, [string]$Pattern)
        (Get-ScriptContent $ScriptName) -match $Pattern
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Estructura de archivos" {

    It "La carpeta de instaladores existe" {
        $InstaladorDir | Should -Exist
    }

    It "Existen todos los scripts esperados" {
        $expected = @(
            "instalar_go.ps1",
            "instalar_nodejs.ps1",
            "instalar_pnpm.ps1",
            "instalar_python312.ps1",
            "instalar_uv.ps1",
            "instalar_volta.ps1",
            "instalar_wails.ps1",
            "install-powershell7.bat"
        )
        foreach ($script in $expected) {
            Join-Path $InstaladorDir $script | Should -Exist -Because "el instalador '$script' debe existir"
        }
    }

    It "Ningun script esta vacio - <_>" -ForEach $AllPS1 {
        $path = Join-Path $InstaladorDir $_
        (Get-Item $path).Length | Should -BeGreaterThan 100 -Because "un script vacio no puede instalar nada"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Sintaxis PowerShell" {

    It "Sintaxis valida en <_>" -ForEach $AllPS1 {
        $path = Join-Path $InstaladorDir $_
        $result = Get-ScriptAST -Path $path
        $result.Errors | Should -BeNullOrEmpty `
            -Because "el script '$_' tiene errores de sintaxis: $($result.Errors -join ', ')"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Elevacion de administrador" {

    It "<_> solicita elevacion de administrador" -ForEach $NeedAdmin {
        Script-Contains $_ "WindowsBuiltInRole.*Administrator" |
            Should -BeTrue `
            -Because "$_ instala a nivel de sistema y requiere permisos de administrador"
    }

    It "<_> usa -Verb RunAs para elevar" -ForEach $NeedAdmin {
        Script-Contains $_ "\-Verb\s+RunAs" |
            Should -BeTrue `
            -Because "$_ debe elevar el proceso con RunAs cuando no tiene admin"
    }

    It "<_> pasa -ExecutionPolicy Bypass al re-lanzarse" -ForEach $NeedAdmin {
        Script-Contains $_ "ExecutionPolicy\s+Bypass" |
            Should -BeTrue `
            -Because "el script re-lanzado necesita bypass para ejecutarse correctamente"
    }

    It "<_> detecta pwsh o powershell al elevar" -ForEach $NeedAdmin {
        Script-Contains $_ "pwsh.*powershell|Get-Command\s+pwsh" |
            Should -BeTrue `
            -Because "debe soportar tanto PowerShell 7 (pwsh) como Windows PowerShell"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Descarga segura (HTTPS)" {

    It "<_> usa HTTPS para descargas" -ForEach $AllPS1 {
        $content = Get-ScriptContent $_
        # Solo aplica si el script hace descargas
        if ($content -match "Invoke-WebRequest|Invoke-RestMethod|https?://") {
            $content | Should -Not -Match "http://" `
                -Because "$_ debe usar HTTPS para todas las descargas"
        }
    }

    It "instalar_go.ps1 descarga desde go.dev" {
        Script-Contains "instalar_go.ps1" "go\.dev/dl" |
            Should -BeTrue -Because "Go debe descargarse desde el sitio oficial go.dev"
    }

    It "instalar_python312.ps1 descarga desde python.org" {
        Script-Contains "instalar_python312.ps1" "python\.org" |
            Should -BeTrue -Because "Python debe descargarse desde python.org"
    }

    It "instalar_volta.ps1 descarga desde github.com/volta-cli" {
        Script-Contains "instalar_volta.ps1" "volta-cli" |
            Should -BeTrue -Because "Volta debe descargarse desde su repositorio oficial"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Limpieza de archivos temporales" {

    It "<_> limpia el instalador temporal despues de instalar" -ForEach $UsesTempDownload {
        Script-Contains $_ "Remove-Item" |
            Should -BeTrue `
            -Because "$_ descarga un instalador y debe borrarlo al terminar"
    }

    It "<_> usa la carpeta TEMP para el instalador" -ForEach $UsesTempDownload {
        Script-Contains $_ "\`$env:TEMP" |
            Should -BeTrue `
            -Because "los instaladores temporales deben guardarse en TEMP, no en el proyecto"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Modo de instalacion visible" {

    It "<_> usa /passive en lugar de /quiet (muestra progreso al usuario)" -ForEach $UsesTempDownload {
        $content = Get-ScriptContent $_
        $content | Should -Match "/passive" `
            -Because "$_ debe mostrar barra de progreso; /quiet es invisible y oculta errores"
        $content | Should -Not -Match "/quiet" `
            -Because "/quiet con -NoNewWindow bloquea la instalacion sin feedback"
    }

    It "<_> guarda log de instalacion para diagnostico" -ForEach $UsesTempDownload {
        Script-Contains $_ "/log" |
            Should -BeTrue `
            -Because "$_ debe generar un log MSI para poder diagnosticar fallos"
    }

    It "<_> verifica el exit code del instalador" -ForEach $UsesTempDownload {
        Script-Contains $_ "ExitCode" |
            Should -BeTrue `
            -Because "$_ debe comprobar si el instalador termino con exito o error"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Refresco de PATH" {

    It "<_> refresca el PATH en la sesion actual despues de instalar" -ForEach $RefreshesPath {
        Script-Contains $_ "GetEnvironmentVariable.*Path.*Machine" |
            Should -BeTrue `
            -Because "$_ debe actualizar `$env:Path para que el comando sea usable inmediatamente"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Verificacion post-instalacion" {

    It "<_> verifica que la herramienta quedo disponible al final" -ForEach $VerifiesInstall {
        Script-Contains $_ "Get-Command\s+\w+.*SilentlyContinue" |
            Should -BeTrue `
            -Because "$_ debe confirmar que el comando instalado es accesible en PATH"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Manejo de errores" {

    It "<_> maneja errores en la descarga" -ForEach @("instalar_go.ps1", "instalar_python312.ps1", "instalar_volta.ps1") {
        Script-Contains $_ "catch" |
            Should -BeTrue `
            -Because "$_ debe manejar errores de red al descargar"
    }

    It "instalar_go.ps1 tiene ErrorActionPreference Stop" {
        Script-Contains "instalar_go.ps1" 'ErrorActionPreference\s*=\s*"Stop"' |
            Should -BeTrue -Because "Stop hace que los errores no pasen desapercibidos"
    }

    It "instalar_wails.ps1 verifica que Go este instalado antes de continuar" {
        Script-Contains "instalar_wails.ps1" "Go no esta instalado|go.*instalado" |
            Should -BeTrue -Because "Wails requiere Go; debe fallar claro si no esta presente"
    }

    It "instalar_pnpm.ps1 verifica que Node.js este instalado antes de continuar" {
        Script-Contains "instalar_pnpm.ps1" "Node.js no esta instalado|node.*instalado" |
            Should -BeTrue -Because "pnpm requiere Node.js; debe fallar claro si no esta presente"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
Describe "Descripcion y cabecera" {

    It "<_> tiene una descripcion en comentario al inicio" -ForEach $AllPS1 {
        $content = Get-ScriptContent $_
        # Primeras 5 lineas deben tener al menos un comentario descriptivo
        $firstLines = ($content -split "`n")[0..4] -join "`n"
        $firstLines | Should -Match "#.{5,}" `
            -Because "$_ debe tener un comentario descriptivo al inicio"
    }
}
