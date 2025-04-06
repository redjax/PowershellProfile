function Install-ProfileModule {
    param(
        [string]$RepositoryPath = $PSScriptRoot,
        [string]$RepoModulesDir = (Join-Path -Path $RepositoryPath -ChildPath "Modules"),
        [string]$ProfileModSrc = (Join-Path -Path $RepoModulesDir -ChildPath "ProfileModule"),
        [string]$ProfileModTar = (Join-Path -Path (Split-Path -Parent $PROFILE) -ChildPath "Modules\ProfileModule")
    )

    Write-Verbose "Repository path: $RepositoryPath"
    Write-Verbose "Source path: $ProfileModSrc"
    Write-Verbose "Target path: $ProfileModTar"

    ## Check if the target path exists
    if (Test-Path -Path $ProfileModTar) {
        Write-Debug "Target path '$($ProfileModTar)' exists. Removing before installing profile module."
        Write-Host "Replacing existing module at $ProfileModTar." -ForegroundColor Cyan

        try {
            Remove-Item -Recurse -Force $ProfileModTar
        }
        catch {
            Write-Error "Error removing path '$ProfileModTar'. Details: $($_.Exception.Message)"
            return
        }
    }

    ## Copy the module to the Modules directory
    Write-Host "Installing ProfileModule to $ProfileModTar." -ForegroundColor Cyan
    try {
        Copy-Item -Recurse -Path $ProfileModSrc -Destination $ProfileModTar
        Write-Host "[SUCCESS] Powershell profile module installed at path: $ProfileModTar" -ForegroundColor Green
        return
    }
    catch {
        Write-Error "[ERROR] Failed to install/update Powershell profile module. Details: $($_.Exception.Message)"
        return
    }
}