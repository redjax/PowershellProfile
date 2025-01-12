<#
    .SYNOPSIS
    My custom PowerShell $PROFILE.

    .DESCRIPTION
    Loads my custom ProfileModule PowerShell module. This module has various functions and aliases
    that I want to import when a PowerShell session loads with this profile.
#>

## Start profile initialization timer
$ProfileStartTime = Get-Date

$ProfileImported = $False
try {
    Import-Module ProfileModule
    $ProfileImported = $True
} catch {
    Write-Error "Error loading ProfileModule. Details: $($_.Exception.Message)"
}

if ( $ProfileImported ) {
    ## Custom profile was imported successfully.
    #  Functions & aliases are available
} else {
    ## Custom profile failed to import.
    #  Functions & aliases are not available
}

## Initialize Starship shell
If ( Get-Command starship ) {
    try {
        Invoke-Expression (&starship init powershell)
    }
    catch {
        ## Show error when verbose logging is enabled
        #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
    }
}

## Clear the screen on fresh sessions
Clear-Host
