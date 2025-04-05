# Pester tests for ActiveDirectoryHelpers module

Describe 'ActiveDirectoryHelpers' {
    It 'Should import the module without errors' {
        Import-Module (Join-Path $PSScriptRoot ".." "ActiveDirectoryHelpers.psm1") -Force
        $Module = Get-Module -Name ActiveDirectoryHelpers
        $Module -eq $null | Should Be $false
    }
}
