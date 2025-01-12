<#
    .SYNOPSIS
    My custom PowerShell $PROFILE.

    .DESCRIPTION
    Loads my custom ProfileModule PowerShell module. This module has various functions and aliases
    that I want to import when a PowerShell session loads with this profile.
#>

# Set the directory where the ProfileModule is located
$ProfileDirectory = (Split-Path -Path $PROFILE -Parent)
$ProfileModulePath = Join-Path -Path $ProfileDirectory -ChildPath "Modules\ProfileModule"

# Attempt to import the ProfileModule
try {
    # Check if the module exists in the module path
    if (Test-Path -Path $ProfileModulePath) {
        Import-Module -Name $ProfileModulePath -Force
        Write-Host "ProfileModule imported successfully." -ForegroundColor Green
    } else {
        Write-Error "ProfileModule not found at '$ProfileModulePath'. Please check the installation."
    }
} catch {
    Write-Error "Failed to import ProfileModule. Details: $($_.Exception.Message)"
}

