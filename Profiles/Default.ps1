<#
    .SYNOPSIS
    My default Powershell $PROFILE.

    Inherits from the _Base.ps1 profile copied during profile install.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1
## Uncomment to enable debug logging
# $DebugPreference = "Continue"

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $true

## Start profile initialization timer
$ProfileStartTime = Get-Date

$ScriptRoot = $PSScriptRoot
$BaseProfile = "$($ScriptRoot)\_Base.ps1"

Write-Output "Importing custom profile, your terminal may slow down for 1-2 seconds."

if (-not (Test-Path -Path "$($BaseProfile)")) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    . "$($BaseProfile)"
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

## Disable profile tracing
Set-PSDebug -Trace 0
