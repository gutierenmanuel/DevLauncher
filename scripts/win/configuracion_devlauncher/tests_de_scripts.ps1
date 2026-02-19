# Script: Ejecutar tests de scripts de Windows
# Lanza la suite de tests local de scripts Windows.

param(
    [switch]$Instaladores,
    [switch]$All,
    [switch]$Verbose,
    [switch]$CI
)

$testsRunner = Join-Path $PSScriptRoot "tests\Run-Tests.ps1"

& $testsRunner @PSBoundParameters
