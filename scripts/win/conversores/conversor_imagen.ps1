# Script: Conversor de imagen por archivo o por lote.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PyTool = Join-Path $ScriptDir "..\..\lib\media_conversor.py"

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

function Select-TargetExtension {
    Write-Host ""
    Write-Host "Formato de salida de imagen (ej: png, jpg, webp, avif, bmp, tiff):"

    $ext = Read-Host "Extensión destino"
    if ([string]::IsNullOrWhiteSpace($ext)) {
        throw "Debes indicar una extensión válida."
    }

    return $ext.Trim().TrimStart('.')
}

function Read-OptionalResize {
    Write-Host ""
    $resize = Read-Host "Resize opcional ANCHOxALTO (ej: 1920x1080, Enter para omitir)"
    return $resize
}

function Read-OptionalQuality {
    Write-Host ""
    $quality = Read-Host "Calidad/compresión opcional 1-100 (Enter para omitir)"
    return $quality
}

function Main {
    try {
        if (-not (Test-Path -LiteralPath $PyTool -PathType Leaf)) {
            throw "No se encontró el motor multimedia: $PyTool"
        }

        $pythonCommand = Resolve-PythonCommand
        $mode = Select-Mode
        $targetExt = Select-TargetExtension
        $resizeValue = Read-OptionalResize
        $qualityValue = Read-OptionalQuality
        $workDir = (Get-Location).Path

        $commonArgs = @("--kind", "image", "--operation", "convert", "--workdir", $workDir, "--target-ext", $targetExt)
        if (-not [string]::IsNullOrWhiteSpace($resizeValue)) {
            $commonArgs += @("--resize", $resizeValue)
        }
        if (-not [string]::IsNullOrWhiteSpace($qualityValue)) {
            $commonArgs += @("--quality", $qualityValue)
        }

        if ($mode -eq "single") {
            $inputPath = Read-Host "Ruta del archivo de imagen"
            & $pythonCommand.Exe @($pythonCommand.Args) $PyTool @commonArgs --mode single --input $inputPath
            if ($LASTEXITCODE -ne 0) {
                Pause-And-Exit 1
            }

            Pause-And-Exit 0
        }

        $filterExt = Read-Host "Extensión origen a procesar (ej: png, jpg, webp)"
        & $pythonCommand.Exe @($pythonCommand.Args) $PyTool @commonArgs --mode all --filter-ext $filterExt
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
