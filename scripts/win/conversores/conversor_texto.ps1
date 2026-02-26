# Script: Conversores de texto (mayúsculas, minúsculas, LF/CRLF) sobre un archivo o por extensión.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Pause-And-Exit([int]$Code = 0) {
    Read-Host "Pulsa Enter para continuar" | Out-Null
    exit $Code
}

function Normalize-Extension([string]$Extension) {
    return $Extension.Trim().TrimStart('.')
}

function Select-Operation {
    Write-Host ""
    Write-Host "Selecciona conversor:"
    Write-Host "1) Convertir contenido a MAYÚSCULAS"
    Write-Host "2) Convertir contenido a minúsculas"
    Write-Host "3) Normalizar saltos de línea a LF"
    Write-Host "4) Normalizar saltos de línea a CRLF"

    $option = Read-Host "Opción"
    switch ($option) {
        "1" { return "upper" }
        "2" { return "lower" }
        "3" { return "lf" }
        "4" { return "crlf" }
        default { throw "Opción inválida" }
    }
}

function Select-Mode {
    Write-Host ""
    Write-Host "Aplicar sobre:"
    Write-Host "1) Un archivo"
    Write-Host "2) Todos los archivos del mismo tipo (extensión)"

    $option = Read-Host "Opción"
    switch ($option) {
        "1" { return "single" }
        "2" { return "all" }
        default { throw "Opción inválida" }
    }
}

function Convert-ContentValue {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Operation
    )

    switch ($Operation) {
        "upper" { return $Content.ToUpperInvariant() }
        "lower" { return $Content.ToLowerInvariant() }
        "lf" {
            $normalized = $Content -replace "`r`n", "`n"
            $normalized = $normalized -replace "`r", "`n"
            return $normalized
        }
        "crlf" {
            $normalized = $Content -replace "`r`n", "`n"
            $normalized = $normalized -replace "`r", "`n"
            return ($normalized -replace "`n", "`r`n")
        }
        default { throw "Conversor no soportado: $Operation" }
    }
}

function Convert-File {
    param(
        [Parameter(Mandatory = $true)][string]$InputFile,
        [Parameter(Mandatory = $true)][string]$Operation,
        [Parameter(Mandatory = $true)][string]$OutputDir
    )

    $fileName = [System.IO.Path]::GetFileName($InputFile)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    $extension = [System.IO.Path]::GetExtension($InputFile)

    $outputFile = Join-Path $OutputDir ("{0}_{1}{2}" -f $baseName, $Operation, $extension)

    $content = Get-Content -LiteralPath $InputFile -Raw
    $converted = Convert-ContentValue -Content $content -Operation $Operation

    Set-Content -LiteralPath $outputFile -Value $converted -Encoding utf8
    Write-Host "✓ Convertido: $fileName -> $outputFile" -ForegroundColor Green
}

function Main {
    try {
        $outputDir = Join-Path (Get-Location).Path "output_conv"
        if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) {
            New-Item -ItemType Directory -Path $outputDir | Out-Null
        }

        $operation = Select-Operation
        $mode = Select-Mode

        if ($mode -eq "single") {
            $inputPath = Read-Host "Ruta del archivo a convertir"
            if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
                throw "No existe el archivo: $inputPath"
            }

            Convert-File -InputFile $inputPath -Operation $operation -OutputDir $outputDir
            Write-Host "Salida en: $outputDir" -ForegroundColor Cyan
            Pause-And-Exit 0
        }

        $extensionInput = Read-Host "Extensión a procesar (ej: txt, md, json)"
        $extension = Normalize-Extension -Extension $extensionInput

        if ([string]::IsNullOrWhiteSpace($extension)) {
            throw "Debes indicar una extensión válida."
        }

        $files = Get-ChildItem -Path (Get-Location).Path -File -Filter "*.$extension"
        if (-not $files -or $files.Count -eq 0) {
            throw "No se encontraron archivos .$extension en la carpeta actual."
        }

        foreach ($file in $files) {
            Convert-File -InputFile $file.FullName -Operation $operation -OutputDir $outputDir
        }

        Write-Host ""
        Write-Host "Conversión finalizada. Archivos generados en: $outputDir" -ForegroundColor Cyan
        Pause-And-Exit 0
    }
    catch {
        Write-Host "✗ $($_.Exception.Message)" -ForegroundColor Red
        Pause-And-Exit 1
    }
}

Main
