Param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$ProfilePath = $PROFILE,
    [string]$PSModulesPath = "$(Split-Path $ProfilePath -Parent)\Modules"
)

If ( $Debug ) {
    $DebugPreference = "Continue"
}

If ( $Verbose ) {
    $VerbosePreference = "Continue"
}

Write-Verbose "Powershell profile path: $($ProfilePath)"
Write-Verbose "Powershell modules path: $($PSModulesPath)"

## Define the source path for PSProfile.ps1 (in the root of the git repository)
$RepoProfilePath = Join-Path (Get-Location) "PSProfile.ps1"
Write-Verbose "Repository Profile path: $($RepoProfilePath)"

## Check if the profile exists
if ( Test-Path $ProfilePath ) {
    ## Backup the existing profile by copying it to $PROFILE.bak (overwriting if exists)
    Write-Host "Backing up existing profile." -ForegroundColor Magenta
    Write-Debug "Move $($ProfilePath) -> $($ProfilePath).bak"
    
    try {
        Move-Item -Path $ProfilePath -Destination "$ProfilePath.bak" -Force
    }
    catch {
        Write-Error "Error backing up existing Powershell profile to path: $($ProfilePath).bak. Details: $($_.Exception.Message)"
        exit 1
    }
}
else {

    ## If no profile exists, create one by copying PSProfile.ps1 to the correct path
    Write-Host "No profile found. Creating a new profile." -ForegroundColor Cyan
}

## Check if PSProfile.ps1 exists
if ( Test-Path $RepoProfilePath ) {
    Write-Host "Install Powershell profile from repository" -ForegroundColor Cyan
    Write-Debug "Copy '$($RepoProfilePath)' to '$($ProfilePath)'"

    Copy-Item -Path $RepoProfilePath -Destination $ProfilePath -Force
    Write-Host "New profile created from PSProfile.ps1." -ForegroundColor Green
}
else {
    Write-Host "PSProfile.ps1 not found at the repository root."
}
