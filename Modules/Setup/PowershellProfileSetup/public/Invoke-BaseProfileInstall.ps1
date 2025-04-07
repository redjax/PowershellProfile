function Invoke-BaseProfileInstall {
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "The path where the base profile will be installed.")]
        [string]$InstallPath = (Join-Path -Path ( Split-Path $PROFILE -Parent ) -ChildPath "\_Base.ps1"),
        [Parameter(Mandatory = $false, HelpMessage = "The path to the .ps1 file to use as the base profile.")]
        [string]$ProfileBase = "_Base.ps1"
    )
    Write-Verbose "Profile base install `$InstallPath: $InstallPath"
    Write-Verbose "Profile base install `$ProfileBasea: $ProfileBase"

    ## Build full path to base profile
    $ProfileBasePath = ( Join-Path -Path ( Join-Path -Path $PSScriptRoot -ChildPath "Profiles" ) -ChildPath "Bases" )
    ## Re-assign $ProfileBase
    $ProfileBase = ( Join-Path -Path $ProfileBasePath -ChildPath $ProfileBase )
    

    if ( -Not $ProfileBase ) {
        Write-Error "-ProfileBase cannot be null"
        exit 1
    }

    ## Check if the profile base exists
    if ( Test-Path $InstallPath ) {
        ## Backup the existing profile by copying it to _Base.ps1.bak (overwriting if exists)
        Write-Host "Backing up existing profile." -ForegroundColor Cyan
        Write-Debug "Move $($InstallPath) -> $($InstallPath).bak"

        try {
            Move-Item -Path $InstallPath -Destination "$InstallPath.bak" -Force
            Write-Host "Existing profile backed up to: $($InstallPath).bak" -ForegroundColor Green
        }
        catch {
            Write-Error "Error backing up existing Powershell profile to path: $($InstallPath).bak. Details: $($_.Exception.Message)"
            return
        }
    }
    else {
        ## If no profile exists, create one by copying ProfileName.ps1 to the correct path
        Write-Host "No profile base found. Creating new _Base.ps1 profile." -ForegroundColor Cyan
    }

    Write-Host "Installing Powershell profile base: $($ProfileBase)" -ForegroundColor Cyan
    ## Check if _Base.ps1 exists
    if ( Test-Path $ProfileBase ) {
        Write-Debug "Copy '$($ProfileBase)' to '$($InstallPath)'"

        Copy-Item -Path $ProfileBase -Destination $InstallPath -Force
        Write-Host "New profile _Base.ps1 created from $($ProfileBase)." -ForegroundColor Green
    }
    else {
        Write-Warning "$($ProfileBase) not found."
        return
    }
}
