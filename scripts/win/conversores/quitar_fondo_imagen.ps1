# Script: Elimina el fondo de imágenes por archivo o por lote.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PyTool = Join-Path $ScriptDir "..\..\lib\remover_fondo.py"

function Pause-And-Exit([int]$Code = 0) {
    Read-Host "Pulsa Enter para continuar" | Out-Null
    exit $Code
}

function Resolve-PythonCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        return @{ Exe = "python"; Args = @() }
    }

    if (Get-Command py -ErrorAction SilentlyContinue) {
        return @{ Exe = "py"; Args = @("-3") }
    }

    throw "No se encontró Python (python o py) en el PATH."
}

function Select-Mode {
    Write-Host ""
    Write-Host "Aplicar sobre:"
    Write-Host "1) Un archivo"
    Write-Host "2) Todos los archivos de una extensión"

    $option = Read-Host "Opción"
    switch ($option) {
        "1" { return "single" }
        "2" { return "all" }
        default { throw "Opción inválida" }
    }
}

function Main {
    try {
        if (-not (Test-Path -LiteralPath $PyTool -PathType Leaf)) {
            throw "No se encontró el script de remover fondo: $PyTool"
        }

        $pythonCommand = Resolve-PythonCommand
        $mode = Select-Mode
        $workDir = (Get-Location).Path

        if ($mode -eq "single") {
            $inputPath = Read-Host "Ruta del archivo de imagen"
            & $pythonCommand.Exe @($pythonCommand.Args) $PyTool --mode single --workdir $workDir --input $inputPath
            if ($LASTEXITCODE -ne 0) {
                Pause-And-Exit 1
            }

            Pause-And-Exit 0
        }

        $filterExt = Read-Host "Extensión origen a procesar (ej: png, jpg, webp)"
        & $pythonCommand.Exe @($pythonCommand.Args) $PyTool --mode all --workdir $workDir --filter-ext $filterExt
        if ($LASTEXITCODE -ne 0) {
            Pause-And-Exit 1
        }

        Pause-And-Exit 0
    }
    catch {
        Write-Host "✗ $($_.Exception.Message)" -ForegroundColor Red
        Pause-And-Exit 1
    }
}

Main
