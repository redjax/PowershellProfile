param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$RepositoryPath = $PSScriptRoot,
    [string]$RepoModulesDir = (Join-Path -Path $RepositoryPath -ChildPath "Modules"),
    [string]$ProfileModSrc = (Join-Path -Path $RepoModulesDir -ChildPath "ProfileModule"),
    [string]$ProfileModTar = (Join-Path -Path (Split-Path -Parent $PROFILE) -ChildPath "Modules\ProfileModule")
)

if ($Debug) {
    $DebugPreference = "Continue"
}
if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Verbose "Repository path: $RepositoryPath"
Write-Verbose "Source path: $ProfileModSrc"
Write-Verbose "Target path: $ProfileModTar"

## Check if the target path exists
if (Test-Path -Path $ProfileModTar) {
    Write-Debug "Target path '$($ProfileModTar)' exists. Removing before installing profile module."
    Write-Output "Replacing existing module at $ProfileModTar."

    try {
        Remove-Item -Recurse -Force $ProfileModTar
    } catch {
        Write-Error "Error removing path '$ProfileModTar'. Details: $($_.Exception.Message)"
        exit 1
    }
}

## Copy the module to the Modules directory
Write-Output "Installing ProfileModule to $ProfileModTar."
try {
    Copy-Item -Recurse -Path $ProfileModSrc -Destination $ProfileModTar
    Write-Output "[SUCCESS] Powershell profile module installed at path: $ProfileModTar"
    exit 0
} catch {
    Write-Error "[ERROR] Failed to install/update Powershell profile module. Details: $($_.Exception.Message)"
    exit 1
}
