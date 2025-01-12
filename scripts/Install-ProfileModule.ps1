Param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$RepositoryPath = $PSScriptRoot,
    [string]$SourcePath = (Join-Path -Path $RepositoryPath -ChildPath "ProfileModule"),
    [string]$TargetPath = (Join-Path -Path (Split-Path -Parent $PROFILE) -ChildPath "Modules\ProfileModule")
)

If ( $Debug ) {
    $DebugPreference = "Continue"
}
If ( $Verbose ) {
    $VerbosePreference = "Continue"
}

Write-Verbose "Repository path: $RepositoryPath"
Write-Verbose "Source path: $SourcePath"
Write-Verbose "Target path: $TargetPath"

## Check if the target path exists
If ( Test-Path -Path $TargetPath ) {
    Write-Debug "Target path '$($TargetPath)' exists. Removing before installing profile module."
    Write-Host "Replacing existing module at $TargetPath." -ForegroundColor Magenta
    
    try {
        Remove-Item -Recurse -Force $TargetPath
    } catch {
        Write-Error "Error removing path '$TargetPath'. Details: $($_.Exception.Message)"
        exit 1
    }
}

## Copy the module to the Modules directory
Write-Host "Installing ProfileModule to $TargetPath." -ForegroundColor Cyan
try {
    Copy-Item -Recurse -Path $SourcePath -Destination $TargetPath
    Write-Host "[SUCCESS] Powershell profile module installed at path: $TargetPath" -ForegroundColor Green
    exit 0
} catch {
    Write-Error "[ERROR] Failed to install/update Powershell profile module. Details: $($_.Exception.Message)"
    exit 1
}
