param(
    [string[]]$cliArgs
)

## Define global preferences for debug & verbose switches
$global:DebugPreference = "SilentlyContinue"
$global:VerbosePreference = "SilentlyContinue"

## Function: Show-Help
function Show-Help {
    param([string[]]$args)

    # General help if no specific command is provided
    if ($args.Count -eq 0 -or $args -contains "--help") {
        Write-Host @"
CLI Help:
Usage: cli.ps1 [--debug|--verbose] <command> <subcommand> [options]

Commands:
  new       Create new resources.
            Subcommands:
              module   Create a new module template.

Global Options:
  --debug   Enable debug mode.
  --verbose Enable verbose mode.

Use --help after a command or subcommand for detailed help.
"@
        return
    }

    # Command-specific help
    switch ($args[0]) {
        "new" {
            if ($args.Count -eq 1) {
                Write-Host @"
Help for 'new' command:
Usage: cli.ps1 new <subcommand> [options]

Subcommands:
  module   Create a new module template.

Use cli.ps1 new <subcommand> --help for detailed help.
"@
            }
            elseif ($args[1] -eq "module") {
                Write-Host @"
Help for 'new module' subcommand:
Usage: cli.ps1 new module [options]

Options:
  --name <string>   Specify the name of the module.
  --custom          Enable custom module creation.
"@
            }
            else {
                Write-Warning "Unknown subcommand '${args[1]}'. Use 'cli.ps1 new --help' for valid options."
            }
        }
        default {
            Write-Warning "Unknown command '${args[0]}'. Use 'cli.ps1 --help' for valid commands."
        }
    }
}

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