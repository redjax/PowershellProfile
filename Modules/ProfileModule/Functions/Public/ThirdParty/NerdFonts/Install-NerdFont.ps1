## Supported NerdFonts and their package names for scoop & choco
$ValidNerdFonts = @"
{
    "FiraMono": {
        "scoop": "FiraMono-NF",
        "choco": "nerd-font-FiraMono"
    },
    "FiraCode": {
        "scoop": "FiraCode-NF",
        "choco": "nerd-font-FiraCode"
    },
    "HackMono": {
        "scoop": "Hack-NF-Mono",
        "choco": "nerdfont-hack"
    },
    "IosevkaTerm": {
        "scoop": "IosevkaTerm-NF-Mono",
        "choco": "nerd-fonts-IosevkaTerm"
    },
    "UbuntuMono": {
        "scoop": "UbuntuMono-NF-Mono",
        "choco": "nerd-fonts-UbuntuMono"
    }
}
"@

function Get-SupportedNerdFonts {
    <#
        .SYNOPSIS
        Get a list of supported nerd fonts.
    #>

    $ValidNerdFonts | Format-List
}

function Start-NerdFontInstall {
    <#
        .SYNOPSIS
        Install a supported nerd font from the command line
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Font,
        [Parameter(Mandatory = $true)]
        [ValidateSet("scoop", "choco")]
        [string]$PkgManager
    )

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
