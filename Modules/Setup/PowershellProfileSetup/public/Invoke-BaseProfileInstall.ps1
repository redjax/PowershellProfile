function Invoke-BaseProfileInstall {
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "The path where the base profile will be installed.")]
        [string]$InstallPath = (Join-Path -Path ( Split-Path $PROFILE -Parent ) -ChildPath "\_Base.ps1"),
        [Parameter(Mandatory = $false, HelpMessage = "The path to the .ps1 file to use as the base profile.")]
        [string]$ProfileBase = "_Base.ps1"
    )
    Write-Verbose "Profile base install `$InstallPath: $InstallPath"
    Write-Verbose "Profile base install `$ProfileBase: $ProfileBase"

    if ( -Not $ProfileBase ) {
        Write-Error "-ProfileBase cannot be null"
        exit 1
    }

    ## Resolve ProfileBase Path
    if ([System.IO.Path]::IsPathRooted($ProfileBase)) {
        # If ProfileBase is already an absolute path, use it directly
        Write-Debug "Using absolute path for ProfileBase: $($ProfileBase)"
    }
    else {
        # If ProfileBase is relative, combine it with ProfilesDir/Bases
        $ProfilesDir = Join-Path -Path $PSScriptRoot -ChildPath "Profiles"
        $BasesDir = Join-Path -Path $ProfilesDir -ChildPath "Bases"
        $ProfileBase = Join-Path -Path $BasesDir -ChildPath $ProfileBase
        Write-Debug "Resolved relative ProfileBase to: $($ProfileBase)"
    }

    ## Validate ProfileBase Path
    if (-Not (Test-Path -Path $ProfileBase)) {
        Write-Error "Profile base not found at path: $($ProfileBase)"
        return
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
