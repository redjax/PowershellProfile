function Start-NerdFontInstall {
    <#
        .SYNOPSIS
        Install a supported nerd font from the command line
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$Font,
        [Parameter(Mandatory = $true)]
        [ValidateSet("scoop", "choco")]
        [string]$PkgManager
    )

    if ( $null -eq $Font ) {
        Write-Warning "A font name is required. Available options:"
        Get-SupportedNerdFonts
    }

    if ( $null -eq $PkgManager ) {
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
