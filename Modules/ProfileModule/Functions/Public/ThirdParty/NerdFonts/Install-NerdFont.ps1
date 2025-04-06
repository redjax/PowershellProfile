## Valid package managers
$ValidPackageManagers = @("winget", "choco", "scoop")

## Supported NerdFonts and their package names for scoop & choco
$ValidNerdFonts = @"
{
    "FiraMono": {
        "scoop": "FiraMono-NF",
        "choco": "nerd-font-FiraMono"
    },
    "FiraCode": {
        "scoop": "FiraCode-NF",
        "choco": "nerd-font-FiraCode"
    },
    "HackMono": {
        "scoop": "Hack-NF-Mono",
        "choco": "nerdfont-hack"
    },
    "IosevkaTerm": {
        "scoop": "IosevkaTerm-NF-Mono",
        "choco": "nerd-fonts-IosevkaTerm"
    },
    "UbuntuMono": {
        "scoop": "UbuntuMono-NF-Mono",
        "choco": "nerd-fonts-UbuntuMono"
    }
}
"@

## Load fonts as JSON data
$FontsJson = $ValidNerdFonts | ConvertFrom-Json

Function Test-IsAdministrator {
    <#
    .SYNOPSIS
    Check if the current user is an administrator.
    #>

    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

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

function Test-ValidPackageManager() {
    Param(
        [Parameter(Mandatory = $true)]
        $PkgManager
    )

    ## Return $True/$False if $PkgManager is in $ValidPackageManagers
    return $ValidPackageManagers -contains $PkgManager
}
