<#
    .SUMMARY
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

If ( -Not ( Test-Path -Path "$($BaseProfile)" ) ) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    ## Load from common _Base.ps1
    #  Wrap slow code to run asynchronously later
    #  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
    @(
        {
            . "$($BaseProfile)"
        }
    ) | ForEach-Object {
        Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
    } | Out-Null
}

If ( $ClearOnInit ) {
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
