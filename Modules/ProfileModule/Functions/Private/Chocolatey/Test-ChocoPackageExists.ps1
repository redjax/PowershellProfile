function Test-ChocoPackageExists() {
    <#
    .SYNOPSIS
    Check if a Chocolatey package exists.

    .PARAMETER PackageName
    The name of the package to check.

    .EXAMPLE
    Test-ChocoPackageExists -PackageName "starship"
    #>
    Param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName
    )
    if (choco list --local-only | Select-String -Pattern "$PackageName") {
        Write-Host "Chocolatey package '$PackageName' is installed."
    }
    else {
        Write-Host "Chocolatey package '$PackageName' is not installed."
    }
}