# Pester tests for PowershellProfileCLI module

Describe 'PowershellProfileCLI' {
    It 'Should import the module without errors' {
        Import-Module (Join-Path $PSScriptRoot ".." "PowershellProfileCLI.psm1") -Force
        $Module = Get-Module -Name PowershellProfileCLI
        $Module -eq $null | Should Be $false
    }
}
