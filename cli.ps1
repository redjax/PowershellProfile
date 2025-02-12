<#
    .SUMMARY
    CLI for the PowershellProfile repository.

    .DESCRIPTION
    Wrap scripts related to operations for managing this repository in Powershell functions.
    Imports the ./scripts/setup/PowershellProfileCLI module and exposes an entrypoint to the user.

    .PARAMETER ModulePath
    Path to the PowershellProfileCLI module. You most likely don't need to change this.
#>
[CmdletBinding(
    ## Set ConfirmPreference above function definitions
    #  to automatically prompt on specified level
    ConfirmImpact = "High"
)]
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
}
elseif ( $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Debug') ) {
    $DebugPreference = "Continue"
    Write-Debug "DEBUG logging enabled."
}
else {
    $VerbosePreference = "SilentlyContinue"
    $DebugPreference = "SilentlyContinue"
}

Write-Debug "Importing PowershellProfileCLI module from path: $($ModulePath)"
try {
    Import-Module $ModulePath -Force
}
catch {
    Write-Error "Error importing the PowershellProfileCLI module. Details: $($_.Exception.Message)"
    exit 1
}

Write-Debug "Getting array of public functions from CLI module."
try {
    $_DiscoveredCommands = (Get-Command -Module PowershellProfileCLI -ErrorAction SilentlyContinue)
}
catch {
    Write-Error "Error getting the PowershellProfileCLI commands. Module may have imported incorrectly. Details: $($_.Exception.Message)"
    exit 1
}

if (
    $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Debug') `
        -or
    $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')
) {
    Write-Debug "Discovered commands:"
    $_DiscoveredCommands | Format-Table
}

# Write-Information "Testing git branch prune script"
# try {
#     Invoke-GitPrune -Confirm -MainBranch "main"
# }
# catch {
#     Write-Error "Error pruning git branches. Details: $($_.Exception.Message)"
#     exit 1
# }