function Invoke-BaseProfileInstall {
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "The path where the base profile will be installed.")]
        [string]$InstallPath = "$(Split-Path $PROFILE -Parent)\_Base.ps1",
        [Parameter(Mandatory = $false, HelpMessage = "The path to the .ps1 file to use as the base profile.")]
        [string]$ProfileBase = "$PSScriptRoot\Profiles\$($ProfileBaseFilename)"
    )
    Write-Verbose "Profile base install `$InstallPath: $InstallPath"
    Write-Verbose "Profile base install `$ProfileBasea: $ProfileBase"

    ## Build full path to base profile directory
    $ProfileBasePath = Join-Path -Path "Profiles" -ChildPath "Bases"
    Write-Host "`n`$ProfileBasePath: $ProfileBasePath`n"

    ## Resolve $ProfileBase correctly
    if ([System.IO.Path]::IsPathRooted($ProfileBase)) {
        # If $ProfileBase is already an absolute path, use it as-is
        Write-Debug "$ProfileBase is an absolute path."
    }
    else {
        ## If $ProfileBase is relative, combine it with $ProfileBasePath
        Write-Debug "$ProfileBase is a relative path. Resolving full path."
        $ProfileBase = Join-Path -Path $ProfileBasePath -ChildPath $ProfileBase
    }
    

    if ( -Not $ProfileBase ) {
        Write-Error "-ProfileBase cannot be null"
        exit 1
    }

    if ( -Not ( Test-Path -Path $ProfileBase -ErrorAction SilentlyContinue ) ) {
        Write-Error "Profile base not found at path: $ProfileBase"
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
