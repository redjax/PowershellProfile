param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$RepositoryPath = $PSScriptRoot,
    [string]$SourcePath = (Join-Path -Path $RepositoryPath -ChildPath "ProfileModule"),
    [string]$TargetPath = (Join-Path -Path (Split-Path -Parent $PROFILE) -ChildPath "Modules\ProfileModule")
)

if ($Debug) {
    $DebugPreference = "Continue"
}
if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Verbose "Repository path: $RepositoryPath"
Write-Verbose "Source path: $SourcePath"
Write-Verbose "Target path: $TargetPath"

## Check if the target path exists
if (Test-Path -Path $TargetPath) {
    Write-Debug "Target path '$($TargetPath)' exists. Removing before installing profile module."
    Write-Output "Replacing existing module at $TargetPath."

    try {
        Remove-Item -Recurse -Force $TargetPath
    } catch {
        Write-Error "Error removing path '$TargetPath'. Details: $($_.Exception.Message)"
        exit 1
    }
}

## Copy the module to the Modules directory
Write-Output "Installing ProfileModule to $TargetPath."
try {
    Copy-Item -Recurse -Path $SourcePath -Destination $TargetPath
    Write-Output "[SUCCESS] Powershell profile module installed at path: $TargetPath"
    exit 0
} catch {
    Write-Error "[ERROR] Failed to install/update Powershell profile module. Details: $($_.Exception.Message)"
    exit 1
}
