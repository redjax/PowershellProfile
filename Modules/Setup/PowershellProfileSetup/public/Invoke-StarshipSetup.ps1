function Invoke-StarshipSetup {
    <#
    .SYNOPSIS
        Performs complete Starship setup for the PowerShell profile.

    .DESCRIPTION
        Handles the complete setup process for Starship:
        1. Checks if Starship is installed (optionally installs it)
        2. Provides guidance on font installation and configuration

    .PARAMETER AutoInstall
        Automatically install Starship if not found (without prompting).

    .PARAMETER PromptForInstall
        Prompt the user to install Starship if not found.

    .PARAMETER SkipFontInfo
        Skip displaying Nerd Font installation information.

    .EXAMPLE
        Invoke-StarshipSetup -PromptForInstall
        Sets up Starship, prompting to install if needed.

    .EXAMPLE
        Invoke-StarshipSetup -AutoInstall
        Automatically installs Starship if needed.

    .NOTES
        This is a high-level setup function that orchestrates the complete Starship setup process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$AutoInstall,

        [Parameter(Mandatory = $false)]
        [switch]$PromptForInstall,

        [Parameter(Mandatory = $false)]
        [switch]$SkipFontInfo
    )

    Write-Host "`n--[ Starship Setup" -ForegroundColor Magenta

    ## Check/Install Starship
    $starshipInstalled = Get-Command "starship" -ErrorAction SilentlyContinue

    if ( -not $starshipInstalled ) {
        if ( $AutoInstall ) {
            Write-Host "Starship not found. Installing automatically" -ForegroundColor Yellow
            $installed = Install-Starship -SkipFontInfo:$SkipFontInfo
            
            if ( -not $installed ) {
                Write-Warning "Failed to install Starship. Setup cannot continue."
                return $false
            }
        }
        elseif ( $PromptForInstall ) {
            Write-Host "Starship is not installed." -ForegroundColor Yellow
            $choice = Read-Host "Would you like to install Starship now? (Y/n)"
            
            if ( $choice -eq '' -or $choice -eq 'y' -or $choice -eq 'Y' ) {
                $installed = Install-Starship -SkipFontInfo:$SkipFontInfo
                
                if ( -not $installed ) {
                    Write-Warning "Failed to install Starship. Setup cannot continue."
                    return $false
                }
            }
            else {
                Write-Host "Skipping Starship installation." -ForegroundColor Yellow
                Write-Host "You can install it later with: Install-Starship" -ForegroundColor Gray
                return $false
            }
        }
        else {
            Write-Warning "Starship is not installed."
            Write-Host "Install it with one of these commands:" -ForegroundColor Yellow
            Write-Host "  PowerShell: Install-Starship" -ForegroundColor Cyan
            Write-Host "  Windows:    winget install Starship.Starship" -ForegroundColor Cyan
            Write-Host "  Windows:    scoop install starship" -ForegroundColor Cyan
            Write-Host "  macOS:      brew install starship" -ForegroundColor Cyan
            Write-Host "  Linux:      curl -sS https://starship.rs/install.sh | sh" -ForegroundColor Cyan
            return $false
        }
    }
    else {
        $version = & starship --version 2>$null
        Write-Host "Starship is installed ($version)" -ForegroundColor Green
    }

    ## Font Information
    if ( -not $SkipFontInfo ) {
        Write-Host ""
        Write-Host "📝 Next Steps:" -ForegroundColor Cyan
        Write-Host "  1. Install a Nerd Font for proper icon display" -ForegroundColor White
        Write-Host "     - Download: https://www.nerdfonts.com/" -ForegroundColor Gray
        Write-Host "     - Windows: scoop install FiraCode-NF" -ForegroundColor Gray
        Write-Host "  2. Configure your terminal to use the Nerd Font" -ForegroundColor White
        Write-Host "  3. Restart your terminal to see the new prompt" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Starship setup completed successfully" -ForegroundColor Green
    return $true
}
