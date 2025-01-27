<#
    .SUMMARY
    Powershell $PROFILE with Starship prompt.
#>
$BaseProfile = ".\_Base.ps1"

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
