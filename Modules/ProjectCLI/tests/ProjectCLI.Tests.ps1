# Pester tests for ProjectCLI module

Describe 'ProjectCLI' {
    It 'Should import the module without errors' {
        Import-Module (Join-Path $PSScriptRoot ".." "ProjectCLI.psm1") -Force
        $Module = Get-Module -Name ProjectCLI
        $Module -eq $null | Should Be $false
    }
}
