## Valid package managers
$ValidPackageManagers = @("winget", "choco", "scoop")

function Test-ValidPackageManager() {
    <#
        .SYNOPSIS
        Check if a package manager is valid by name.

        .DESCRIPTION
        My modules support winget, scoop, and chocolatey, generally.
    #>
    Param(
        [Parameter(Mandatory = $true)]
        $PkgManager
    )

    ## Return $True/$False if $PkgManager is in $ValidPackageManagers
    return $ValidPackageManagers -contains $PkgManager
}