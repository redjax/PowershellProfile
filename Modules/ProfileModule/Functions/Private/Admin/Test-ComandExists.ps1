function Test-CommandExists {
    <#
    .SYNOPSIS
    Check if a command exists/executes.

    .PARAMETER Command
    The command to check.

    .EXAMPLE
    Test-CommandExists "winget"
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $CmdExists = ($null -ne (Get-Command $Command -ErrorAction SilentlyContinue))
    Write-Verbose "Command '$Command' exists: $CmdExists."

    return $CmdExists
}