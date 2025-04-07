<#
    .SYNOPSIS
    Powershell $PROFILE with Starship prompt.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1
## Uncomment to enable debug logging
# $DebugPreference = "Continue"

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $true

## Start profile initialization timer
$ProfileStartTime = Get-Date

# ## Create a ManualResetEvent object for starship's init state
# $Global:StarshipInitialized = New-Object System.Threading.ManualResetEvent $false

$ScriptRoot = $PSScriptRoot

function Start-StarshipInit {
    Write-Debug "Starting Starship initialization"

    ## Initialize Starship shell
    Invoke-Expression (& starship init powershell)
}

## End profile initialization timer
$ProfileEndTime = Get-Date
## Calculate profile init time
$ProfileInitTime = $ProfileEndTime - $ProfileStartTime
## Print initialization time
Write-Output "Profile loaded in $($ProfileInitTime.TotalSeconds) second(s)."
Write-Output "Some commands may be unavailable for 1-3 seconds while background imports finish."

## Disable profile tracing
Set-PSDebug -Trace 0
