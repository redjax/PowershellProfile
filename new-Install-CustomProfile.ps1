Param(
    [Parameter(HelpMessage = "Path to the PowershellProfileCLI module")]
    [string]$ModulePath = (Join-Path $PSScriptRoot "scripts/setup/PowershellProfileCLI")
)

## Enable informational logging
$InformationPreference = "Continue"

if ( $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose') ) {
    $VerbosePreference = "Continue"
    $DebugPreference = "Continue"
    Write-Verbose "DEBUG and VERBOSE logging enabled."
} elseif ( $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Debug') ) {
    $DebugPreference = "Continue"
    Write-Debug "DEBUG logging enabled."
} else {
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"
}

Write-Debug "PowershellProfileCLI Module path: $($ModulePath)"

Write-Information "Importing PowershellProfileCLI module from path: $($ModulePath)"
try {
    Import-Module $ModulePath -Force -Verbose
} catch {
    Write-Error "Error importing the PowershellProfileCLI module. Details: $($_.Exception.Message)"
    exit 1
}

Write-Information "Listing PowershellProfileCLI commands."
try {
    Get-Command -Module Get-PowershellProfileCLI
} catch {
    Write-Error "Error getting the PowershellProfileCLI commands. Module may have imported incorrectly. Details: $($_.Exception.Message)"
    exit 1
}

Write-Information "Testing git branch prune script"
try {
    Prune-GitBranches
} catch {
    Write-Error "Error pruning git branches. Details: $($_.Exception.Message)"
    exit 1
}