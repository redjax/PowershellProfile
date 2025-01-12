<#
    .SYNOPSIS
    My custom PowerShell $PROFILE.

    .DESCRIPTION
    Loads my custom ProfileModule PowerShell module. This module has various functions and aliases
    that I want to import when a PowerShell session loads with this profile.
#>

try {
    Import-Module ProfileModule
} catch {
    Write-Error "Error loading ProfileModule. Details: $($_.Exception.Message)"
}