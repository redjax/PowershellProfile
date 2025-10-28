function Invoke-NerdFontInstall {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$PkgManager,
        [string]$FontName = "FiraMono"
    )

    If ( $DryRun ) {
        Write-Host "[DryRun] Would have installed a Nerd Font with $( if ($PkgManager -eq "winget") {"scoop"} else { $PkgManager })." -ForegroundColor Magenta
        return
    }

    if ( $PkgManager -eq "winget" ) {
        Write-Warning "Installing NerdFonts with winget is not supported. Setting package manager to 'scoop'. If scoop is not installed, script will exit."
        $PkgManager = "scoop"
    }

    Write-Debug "NerdFont: '$($FontName)', package manager: $PkgManager"

    If ( -Not ( Test-CommandExists "$($PkgManager)" ) ) {
        Write-Error "Package manager '$($PkgManager)' is not installed."
        exit 1
    }

    switch ($PkgManager) {

        "scoop" {
            Write-Debug "Using scoop package manager"

            ## Test if nerdfont is already installed.
            $NerdFontInstalled = Test-ScoopPackageExists -PackageName $FontName
            Write-Debug "NerdFont '$($FontName)' installed: $NerdFontInstalled."

            If ( $NerdFontInstalled ) {
                Write-Host "NerdFont '$($FontName)' is already installed." -ForegroundColor Cyan
                return
            }

            ## Check if the FontName exists in the JSON data
            if ( -not $FontsJson.PSObject.Properties.Name -contains $FontName ) {
                Write-Error "Font '$FontName' not found in the mapping."
                return $null
            }

            ## Retrieve font object from JSON
            $FontDetails = $FontsJson.$FontName
            Write-Debug "NerdFont '$($FontName)' details: $FontDetails."

            Write-Host "Installing NerdFont '$($FontName)' with scoop" -ForegroundColor Cyan

            ## Install NerdFont with Scoop.
            try {
                scoop install $FontDetails.scoop
                return
            }
            catch {
                Write-Error "Failed to install Starship with Scoop."
                return $false
            }
        }

        "choco" {
            Write-Debug "Using chocolatey package manager"

            ## Test if nerdfont is already installed.
            $NerdFontInstalled = Test-ChocoPackageExists -PackageName $FontName
            Write-Debug "NerdFont '$($FontName)' installed: $NerdFontInstalled."

            If ( $NerdFontInstalled ) {
                Write-Host "NerdFont '$($FontName)' is already installed." -ForegroundColor Cyan
                return
            }

            ## Check if the FontName exists in the JSON data
            if ( -not $FontsJson.PSObject.Properties.Name -contains $FontName ) {
                Write-Error "Font '$FontName' not found in the mapping."
                return $null
            }

            ## Retrieve font object from JSON
            $FontDetails = $FontsJson.$FontName
            Write-Debug "NerdFont '$($FontName)' details: $FontDetails."

            Write-Host "Installing NerdFont '$($FontName)' with chocolatey" -ForegroundColor Cyan

            ## Install NerdFont with Chocolatey.
            try {
                choco install $fontDetails.choco -y
                return
            }
            catch {
                Write-Error "Failed to install NerdFont with Chocolatey."
                return $false
            }
        }

        "winget" {
            Write-Error "NerdFonts are not available for install with winget. Use scoop or chocolatey."
            exit 1
        }

        default { Write-Error "Unknown package manager: $PkgInstaller" ; exit 1 }
    }
}