<#
    .SYNOPSIS
    Monolithic PowerShell $PROFILE - modular components sourced into single session.

    .DESCRIPTION
    A PowerShell profile composed of smaller, maintainable component files:
    - namespaces.ps1: Type shortcuts
    - psreadline-handlers.ps1: Advanced key bindings
    - prompt.ps1: Starship prompt initialization
    - shell-completions.ps1: CLI tool completions
    - aliases.ps1: Unix-like aliases and functions
    - software-init.ps1: Third-party tool initialization
    
    All components must be in the ProfileComponents subdirectory within the profile directory.
    The installer (Install-MonoProfile.ps1) copies all necessary files to the profile directory.
#>

## Start profile timing
$ProfileStartTime = Get-Date

## Get the profile directory and ProfileComponents subdirectory
$ProfileDir = Split-Path -Path $PROFILE -Parent
$ComponentsDir = Join-Path $ProfileDir "ProfileComponents"

## Source all component files
$components = @(
    'namespaces.ps1'
    'psreadline-handlers.ps1'
    'prompt.ps1'
    'shell-completions.ps1'
    'aliases.ps1'
    'software-init.ps1'
)

foreach ( $component in $components ) {
    $componentPath = Join-Path $ComponentsDir $component
    if ( Test-Path $componentPath ) {
        try {
            . $componentPath
            Write-Verbose "Loaded: $component"
        }
        catch {
            Write-Warning "Failed to load $component : $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Component not found: $componentPath"
    }
}

##############################################################
# PROFILE load finished                                      #
# Leave this at the bottom, and don't put anything after it. #
##############################################################

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
Write-Output "$($ProfileInitTime.TotalSeconds)s"

## No code below this line
