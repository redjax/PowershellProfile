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