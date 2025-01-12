param(
    [switch]$Debug,
    [switch]$Verbose,
    [string]$ProfilePath = $PROFILE,
    [string]$PSModulesPath = "$(Split-Path $ProfilePath -Parent)\Modules",
    [string]$ProfileName = "DefaultProfile"
)

if ($Debug) {
    $DebugPreference = "Continue"
}

if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Verbose "Powershell profile path: $($ProfilePath)"
Write-Verbose "Powershell modules path: $($PSModulesPath)"

## Repository profiles path
$RepoProfilesDir = Join-Path (Get-Location) "Profiles"
## Define the source path for ProfileName.ps1 (in the root of the git repository)
$RepoProfilePath = Join-Path $RepoProfilesDir "$($ProfileName).ps1"
Write-Verbose "Repository Profile path: $($RepoProfilePath)"

## Check if the profile exists
if (Test-Path $ProfilePath) {
    ## Backup the existing profile by copying it to $PROFILE.bak (overwriting if exists)
    Write-Output "Backing up existing profile."
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

    ## If no profile exists, create one by copying ProfileName.ps1 to the correct path
    Write-Output "No profile found. Creating a new profile."
}

## Check if ProfileName.ps1 exists
if (Test-Path $RepoProfilePath) {
    Write-Output "Install Powershell profile from repository"
    Write-Debug "Copy '$($RepoProfilePath)' to '$($ProfilePath)'"

    Copy-Item -Path $RepoProfilePath -Destination $ProfilePath -Force
    Write-Output "New profile created from $($ProfileName).ps1."
}
else {
    Write-Output "$($ProfileName).ps1 not found at the repository root."
}
