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

$ScriptRoot = $PSScriptRoot
$BaseProfile = "$($ScriptRoot)\_StarshipBase.ps1"

## Create a ManualResetEvent object for starship's init state
$Global:StarshipInitialized = New-Object System.Threading.ManualResetEvent $false

if (-not (Test-Path -Path "$($BaseProfile)")) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    . "$($BaseProfile)"
}

# ## Initialize Starship in the background
# #  Wrap slow code to run asynchronously later
# #  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
# @(
#     {
#         ## Initialize Starship shell
#         Start-StarshipInit
#     }
# ) | ForEach-Object {
#     Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $_
# } | Out-Null

# if ($ClearOnInit) {
#     Clear-Host
# }

## Initialize Starship in the background
#  Wrap slow code to run asynchronously later
#  https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
@(
    {
        try {
            Start-StarshipInit
            ## Indicate to the script that the ProfileModule was imported successfully
            $Global:StarshipInitialized = $true
            ## Signal that the module was successfully imported
            $Global:StarshipInitialized.Set()
        }
        catch {
            Write-Error "Error initializing Starship. Details: $($_.Exception.Message)"
            ## Signal even if there's an error
            $Global:StarshipInitialized.Set()
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

## Disable profile tracing
Set-PSDebug -Trace 0
