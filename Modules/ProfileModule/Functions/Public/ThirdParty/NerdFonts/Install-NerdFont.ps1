function Install-NerdFont {
    <#
        .SYNOPSIS
        Install a supported nerd font from the command line
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Name of a supported NerdFont to install.")]
        [string]$Font = $null,
        [Parameter(Mandatory = $false, HelpMessage = "The package manager to install the NerdFont with. Options: scoop, choco. (default=scoop)")]
        [ValidateSet("scoop", "choco")]
        [string]$PkgManager = "scoop"
    )

    if ( -not $Font ) {
        Write-Warning "A font name is required."
        Write-Output "`n[ Supported Font Names ]"
        $SupportedFonts = Get-SupportedNerdFonts
        ## Convert the JSON string to a PowerShell object
        $ParsedNerdFonts = $SupportedFonts | ConvertFrom-Json

        ## Get and print only the keys
        $ParsedNerdFonts.PSObject.Properties.Name

        Write-Output "`nRe-run the function, passing one of the font names above as -Font `$FontName"

        exit(1)
    }

    if ( -not $PkgManager ) {
        Write-Warning "Must specify a package manager. Available options: scoop, choco"
        exit(1)
    }

    switch ($PkgManager) {
        "scoop" {
            if ( -Not ( Get-Command scoop -ErrorAction SilentlyContinue ) ) {
                Write-Error "Scoop is not installed."
                exit(1)
            }
            Write-Debug "Using scoop package manager"
        }
        "choco" {
            if ( -Not ( Get-Command choco -ErrorAction SilentlyContinue ) ) {
                Write-Error "Chocolatey is not installed."
                exit(1)
            }
            Write-Debug "Using chocolatey package manager"
        }
    }

    Write-Output "Installing NerdFont: $($Font)"

    try {
        Invoke-NerdFontInstall -PkgManager $PkgManager -FontName $Font
    }
    catch {
        Write-Error "Failed to install NerdFont: $($Font)"
        exit(1)
    }

    Write-Output "Installed NerdFont: $($Font)"
}
