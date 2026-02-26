# Script: Conversor de datos tabulares (Excel/CSV/JSON/Parquet) por archivo o por lote.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PyTool = Join-Path $ScriptDir "..\..\lib\datos_tabulares.py"

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
    Write-Host "Selecciona conversión tabular:"
    Write-Host "1) Excel -> CSVs (uno por hoja)"
    Write-Host "2) CSV -> Excel"
    Write-Host "3) JSON -> CSV"
    Write-Host "4) CSV -> JSON"
    Write-Host "5) JSON -> Excel"
    Write-Host "6) Excel -> JSON (uno por hoja)"
    Write-Host "7) Parquet -> CSV"
    Write-Host "8) CSV -> Parquet"
    Write-Host "9) Parquet -> JSON"
    Write-Host "10) JSON -> Parquet"
    Write-Host "11) Parquet -> Excel"
    Write-Host "12) Excel -> Parquet (uno por hoja)"
    Write-Host "13) XML -> CSV"
    Write-Host "14) CSV -> XML"
    Write-Host "15) SQLite -> CSVs (uno por tabla)"
    Write-Host "16) CSV -> SQLite"
    Write-Host "17) SQLite -> Excel"
    Write-Host "18) Excel -> SQLite"
    Write-Host "19) ODS -> CSVs (uno por hoja)"
    Write-Host "20) CSV -> ODS"
    Write-Host "21) ODS -> Excel"
    Write-Host "22) Excel -> ODS"
    Write-Host "23) YAML -> JSON"
    Write-Host "24) JSON -> YAML"
    Write-Host "25) YAML -> CSV"
    Write-Host "26) CSV -> YAML"
    Write-Host "27) CSV -> CSV.GZ"
    Write-Host "28) CSV.GZ -> CSV"
    Write-Host "29) JSON -> JSON.GZ"
    Write-Host "30) JSON.GZ -> JSON"
    Write-Host "31) Parquet -> Feather"
    Write-Host "32) Feather -> Parquet"
    Write-Host "33) JSON -> JSONL"
    Write-Host "34) JSONL -> JSON"
    Write-Host "35) ENV -> JSON"
    Write-Host "36) JSON -> ENV"
    Write-Host "37) INI -> YAML"
    Write-Host "38) YAML -> INI"
    Write-Host "39) CSV -> SQL INSERT"
    Write-Host "40) JSON -> SQL INSERT"
    Write-Host "41) SQL INSERT -> CSV"
    Write-Host "42) SQL INSERT -> JSON"

    $option = Read-Host "Opción"
    switch ($option) {
        "1" { return "excel_to_csvs" }
        "2" { return "csv_to_excel" }
        "3" { return "json_to_csv" }
        "4" { return "csv_to_json" }
        "5" { return "json_to_excel" }
        "6" { return "excel_to_json" }
        "7" { return "parquet_to_csv" }
        "8" { return "csv_to_parquet" }
        "9" { return "parquet_to_json" }
        "10" { return "json_to_parquet" }
        "11" { return "parquet_to_excel" }
        "12" { return "excel_to_parquet" }
        "13" { return "xml_to_csv" }
        "14" { return "csv_to_xml" }
        "15" { return "sqlite_to_csv" }
        "16" { return "csv_to_sqlite" }
        "17" { return "sqlite_to_excel" }
        "18" { return "excel_to_sqlite" }
        "19" { return "ods_to_csv" }
        "20" { return "csv_to_ods" }
        "21" { return "ods_to_excel" }
        "22" { return "excel_to_ods" }
        "23" { return "yaml_to_json" }
        "24" { return "json_to_yaml" }
        "25" { return "yaml_to_csv" }
        "26" { return "csv_to_yaml" }
        "27" { return "csv_to_csv_gz" }
        "28" { return "csv_gz_to_csv" }
        "29" { return "json_to_json_gz" }
        "30" { return "json_gz_to_json" }
        "31" { return "parquet_to_feather" }
        "32" { return "feather_to_parquet" }
        "33" { return "json_to_jsonl" }
        "34" { return "jsonl_to_json" }
        "35" { return "env_to_json" }
        "36" { return "json_to_env" }
        "37" { return "ini_to_yaml" }
        "38" { return "yaml_to_ini" }
        "39" { return "csv_to_sql_insert" }
        "40" { return "json_to_sql_insert" }
        "41" { return "sql_insert_to_csv" }
        "42" { return "sql_insert_to_json" }
        default { throw "Opción inválida" }
    }
}

function Select-Mode {
    Write-Host ""
    Write-Host "Aplicar sobre:"
    Write-Host "1) Un archivo"
    Write-Host "2) Todos los archivos del tipo de origen"

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
            throw "No se encontró el motor de conversión: $PyTool"
        }

        $pythonCommand = Resolve-PythonCommand
        $operation = Select-Operation
        $mode = Select-Mode
        $workDir = (Get-Location).Path

        if ($mode -eq "single") {
            $inputPath = Read-Host "Ruta del archivo a convertir"
            & $pythonCommand.Exe @($pythonCommand.Args) $PyTool --operation $operation --mode single --workdir $workDir --input $inputPath
            if ($LASTEXITCODE -ne 0) {
                Pause-And-Exit 1
            }

            Pause-And-Exit 0
        }

        & $pythonCommand.Exe @($pythonCommand.Args) $PyTool --operation $operation --mode all --workdir $workDir
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
