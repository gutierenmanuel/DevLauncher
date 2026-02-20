param(
    [switch]$Verbose,
    [switch]$CI
)

$ErrorActionPreference = "Stop"

$testsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:DL_PUERTOS_SCRIPT = (Resolve-Path (Join-Path $testsRoot "..\..\..\gestion_windows\puertos_activos.ps1")).Path

$pester = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester -or $pester.Version -lt [version]"5.0") {
    Install-Module -Name Pester -MinimumVersion 5.0 -Force -Scope CurrentUser -SkipPublisherCheck
}

Import-Module Pester -MinimumVersion 5.0

$config = New-PesterConfiguration
$config.Output.Verbosity = if ($Verbose) { "Detailed" } else { "Normal" }
$config.Output.CIFormat = if ($CI) { "GithubActions" } else { "Auto" }
$config.Run.Path = $testsRoot
$config.Run.PassThru = $true

$result = Invoke-Pester -Configuration $config

if ($CI) {
    exit $result.FailedCount
}
