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

Write-Output "Importing custom profile, your terminal may slow down for 1-2 seconds."

If ( -Not ( Test-Path -Path "$($BaseProfile)" ) ) {
    Write-Warning "Could not find base profile '$($BaseProfile)'."
}
else {
    . "$($BaseProfile)"

    ## Set the prompt, if available
    If ( (Get-Command Get-Prompt -ErrorAction SilentlyContinue ) ) {
        function Prompt {
            <#
                .SUMMARY
                Override the built-in Powershell prompt with the profile's custom prompt
            #>

            return Get-Prompt
        }
    } else {
        Write-Warning "No custom Get-Prompt command defined in `$PROFILE. Falling back to default Powershell prompt."
    }

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
