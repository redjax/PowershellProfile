function Set-LoggingLevel {
    param (
        [switch]$Verbose,
        [switch]$Debug
    )

    ## Explicitly set preferences based on the actual parameters passed
    if ($Verbose) {
        $VerbosePreference = "Continue"
        $DebugPreference = "Continue"
        Write-Verbose "DEBUG and VERBOSE logging enabled."
    }
    elseif ($Debug) {
        $DebugPreference = "Continue"
        Write-Debug "DEBUG logging enabled."
    }
    else {
        $VerbosePreference = "SilentlyContinue"
        $DebugPreference = "SilentlyContinue"
    }
}