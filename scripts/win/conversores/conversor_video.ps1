# Script: Conversor de video (formato o extracción de audio) por archivo o por lote.

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

function Select-Operation {
    Write-Host ""
    Write-Host "Conversor de video:"
    Write-Host "1) Convertir formato de video"
    Write-Host "2) Extraer audio del video"

    $option = Read-Host "Opción"
    switch ($option) {
        "1" { return "convert" }
        "2" { return "extract_audio" }
        default { throw "Opción inválida" }
    }
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

function Select-TargetExtension([string]$Operation) {
    Write-Host ""
    if ($Operation -eq "convert") {
        Write-Host "Formato de salida de video (ej: mp4, webm, mkv, mov, avi):"
    }
    else {
        Write-Host "Formato de salida de audio (ej: mp3, wav, flac, aac, ogg):"
    }

    $ext = Read-Host "Extensión destino"
    if ([string]::IsNullOrWhiteSpace($ext)) {
        throw "Debes indicar una extensión válida."
    }

    return $ext.Trim().TrimStart('.')
}

function Main {
    try {
        if (-not (Test-Path -LiteralPath $PyTool -PathType Leaf)) {
            throw "No se encontró el motor multimedia: $PyTool"
        }

        $pythonCommand = Resolve-PythonCommand
        $operation = Select-Operation
        $mode = Select-Mode
        $targetExt = Select-TargetExtension -Operation $operation
        $workDir = (Get-Location).Path

        if ($mode -eq "single") {
            $inputPath = Read-Host "Ruta del archivo de video"
            & $pythonCommand.Exe @($pythonCommand.Args) $PyTool --kind video --operation $operation --mode single --workdir $workDir --target-ext $targetExt --input $inputPath
            if ($LASTEXITCODE -ne 0) {
                Pause-And-Exit 1
            }

            Pause-And-Exit 0
        }

        $filterExt = Read-Host "Extensión origen a procesar (ej: mp4, webm, mkv)"
        & $pythonCommand.Exe @($pythonCommand.Args) $PyTool --kind video --operation $operation --mode all --workdir $workDir --target-ext $targetExt --filter-ext $filterExt
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
