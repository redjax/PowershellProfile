<#
    .SYNOPSIS
    Powershell $PROFILE with Starship prompt.
#>

## Uncomment to enable profile tracing
# Set-PSDebug -Trace 1

## Manually set this to $false to keep profile outputs on-screen after initializing
$ClearOnInit = $true

## Start profile initialization timer
$ProfileStartTime = Get-Date

$ScriptRoot = $PSScriptRoot
$BaseProfile = "$($ScriptRoot)\_Base.ps1"

if (-not (Test-Path -Path "$($BaseProfile)")) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    . "$($BaseProfile)"
}

## Initialize Starship in the background
#  Wrap slow code to run asynchronously later
#  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
@(
    {
        ## Initialize Starship shell
        if (Get-Command starship -ErrorAction SilentlyContinue) {
            Invoke-Expression (& starship init powershell)
        }
    }
) | ForEach-Object {
    Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
} | Out-Null

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
