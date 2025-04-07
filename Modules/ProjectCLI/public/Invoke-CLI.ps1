function Invoke-CLI {
    [CmdletBinding()]
    param(
        [string[]]$cliArgs
    )

    ## Define global preferences for debug & verbose switches
    $global:DebugPreference = "SilentlyContinue"
    $global:VerbosePreference = "SilentlyContinue"

    ## Parse global args (--debug/--verbose)
    if ( $cliArgs -contains "--debug" ) {
        $global:DebugPreference = "Continue"
        Write-Debug "Debug logging enabled."
    }

    if ( $cliArgs -contains "--verbose" ) {
        $global:VerbosePreference = "Continue"
        Write-Verbose "Verbose logging enabled."
    }

    ## Handle --help argument or no arguments
    if ($cliArgs.Count -eq 0 -or $cliArgs -contains "--help") {
        Show-Help $cliArgs
        exit 0
    }

    ## Extract main command & subcommand
    if ( $cliArgs.Count -gt 0 ) {
        $command = $cliArgs[0]

        $subcommand = if ( $cliArgs.Count -gt 1 ) { $cliArgs[1] } else { $null }

        $remainingArgs = $cliArgs[2..( $cliArgs.Count - 1 )]
    }
    else {
        Write-Warning "No command provided. Use --help for usage information."
        exit 1
    }

    ## Dispatch commands
    switch ( $command ) {
        "new" {
            if ( $subcommand -eq "module" ) {
                Write-Debug "Initializing new module"
                ## Forward to New-ModuleTemplate script with parsed args
                & "$PSScriptRoot/scripts/New-ModuleTemplate.ps1" @remainingArgs
            }
            else {
                Write-Warning "Unknown subcommand '$subcommand' for 'new'."
            }
        }
        default {
            Write-Warning "Unknown command: '$command'. Use --help for usage information."
            exit 1
        }
    }
}