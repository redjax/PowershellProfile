[CmdletBinding()]
[string]$CliModulePath = ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath "Modules" ) -ChildPath "ProjectCLI" )

Write-Verbose "CLI module path: $CliModulePath"

## Test for Invoke-CLI, import module if not present
if ( -Not ( Get-Command Invoke-CLI -ErrorAction SilentlyContinue ) ) {
    Write-Debug "Importing CLI module from path: $CliModulePath"

    try {
        Import-Module $CliModulePath -ErrorAction Stop
        Write-Debug "Imported module from path $CliModulePath"
    }
    catch {
        Write-Error "Error importing CLI module. Details: $($_.Exception.Message)"
        exit 1
    }
}

## Re-test Invoke-CLI command
if ( -Not ( Get-Command Invoke-CLI -ErrorAction SilentlyContinue ) ) {
    Write-Error "Invoke-CLI command is still unavailable, even after import module: $CliModulePath"
    exit 1
}

Write-Debug "Executing CLI with $($args.Count) arg(s)"
## Forward execution to the CLI
try {
    & Invoke-CLI @args
}
catch {
    Write-Error "Error executing CLI. Details: $($_.Exception.Message)"
    exit 1
}