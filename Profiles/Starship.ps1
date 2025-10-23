<#
    .SYNOPSIS
    Powershell $PROFILE with Starship prompt.

    .DESCRIPTION
    Loads the _StarshipBase.ps1 base profile which includes:
    - Custom ProfileModule
    - Custom modules from CustomModules directory
    
    Then initializes Starship prompt in the background.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1

## Uncomment to enable debug logging
# $DebugPreference = "Continue"

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $true

## Start profile initialization timer
$ProfileStartTime = Get-Date

$ScriptRoot = Split-Path -Path $PROFILE -Parent
$BaseProfile = Join-Path -Path $ScriptRoot -ChildPath "_Base.ps1"

if (-not (Test-Path -Path "$($BaseProfile)")) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    . "$($BaseProfile)"
}

## Initialize Starship prompt
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}
else {
    Write-Warning "Starship is not installed."
    Write-Host "Install with: winget install Starship.Starship" -ForegroundColor Cyan
}

if ($ClearOnInit) {
    Clear-Host
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
