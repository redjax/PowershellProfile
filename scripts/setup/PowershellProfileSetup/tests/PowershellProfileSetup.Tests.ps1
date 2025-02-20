# Pester tests for PowershellProfileSetup module

Describe 'PowershellProfileSetup' {
    It 'Should import the module without errors' {
        Import-Module (Join-Path $PSScriptRoot ".." "PowershellProfileSetup.psm1") -Force
        $Module = Get-Module -Name PowershellProfileSetup
        $Module -eq $null | Should Be $false
    }
}
