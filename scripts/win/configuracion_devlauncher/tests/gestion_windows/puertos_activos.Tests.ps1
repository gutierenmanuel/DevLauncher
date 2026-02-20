#Requires -Modules Pester

$ErrorActionPreference = "Stop"

Describe "puertos_activos.ps1 - regresion de ParserError" {
    BeforeAll {
        $script:ScriptPath = $env:DL_PUERTOS_SCRIPT
        if (-not $script:ScriptPath) {
            $script:ScriptPath = Join-Path (Get-Location).Path "scripts\win\gestion_windows\puertos_activos.ps1"
        }
    }

    It "tiene sintaxis PowerShell valida" {
        $tokens = $null
        $errors = $null

        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $script:ScriptPath,
            [ref]$tokens,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }

    It "usa delimitacion explicita en processName antes de ':'" {
        $content = Get-Content -Path $script:ScriptPath -Raw

        $content | Should -Match '\$\{processName\}:'
        $content | Should -Not -Match '\$processName:'
    }
}
