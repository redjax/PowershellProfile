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

# $VerbosePreference = if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { "Continue" } else { "SilentlyContinue" }
# $DebugPreference = if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { "Continue" } else { "SilentlyContinue" }

Write-Debug "Importing PowershellProfileCLI module from path: $($ModulePath)"
try {
    Import-Module $ModulePath -Force
}
catch {
    Write-Error "Error importing the PowershellProfileCLI module. Details: $($_.Exception.Message)"
    exit 1
}

# Set-LoggingLevel -Verbose:$Verbose -Debug:$Debug

Write-Debug "Getting array of public functions from CLI module."
try {
    $_DiscoveredCommands = (Get-Command -Module PowershellProfileCLI -ErrorAction SilentlyContinue)
}
catch {
    Write-Error "Error getting the PowershellProfileCLI commands. Module may have imported incorrectly. Details: $($_.Exception.Message)"
    exit 1
}

if (
    $_Debug -or $_Verbose
) {
    Write-Debug "Discovered commands:"
    $_DiscoveredCommands | Format-Table
}

$cliParams = @{
    Operation = "prune-branches"
    Debug     = $Debug
    Verbose   = $Verbose
    Args      = @{
        "MainBranch" = "main"
    }
}
## Call the CLI
Invoke-Cli @cliParams

# Write-Information "Testing git branch prune script"
# try {
#     Invoke-GitPrune -Confirm -MainBranch "main"
# }
# catch {
#     Write-Error "Error pruning git branches. Details: $($_.Exception.Message)"
#     exit 1
# }