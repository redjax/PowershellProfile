function Invoke-OhMyPoshSetup {
    <#
    .SYNOPSIS
        Performs complete Oh My Posh setup for the PowerShell profile.

    .DESCRIPTION
        Handles the complete setup process for Oh My Posh:
        1. Checks if Oh My Posh is installed (optionally installs it)
        2. Validates/creates the theme configuration
        3. Provides guidance on font installation

    .PARAMETER RepositoryPath
        Path to the PowerShell profile repository root.

    .PARAMETER AutoInstall
        Automatically install Oh My Posh if not found (without prompting).

    .PARAMETER PromptForInstall
        Prompt the user to install Oh My Posh if not found.

    .PARAMETER CreateDefaultTheme
        Create a default theme if one doesn't exist.

    .PARAMETER SkipFontInfo
        Skip displaying Nerd Font installation information.

    .EXAMPLE
        Invoke-OhMyPoshSetup -RepositoryPath "C:\repos\PowershellProfile" -PromptForInstall
        Sets up Oh My Posh, prompting to install if needed.

    .EXAMPLE
        Invoke-OhMyPoshSetup -RepositoryPath "C:\repos\PowershellProfile" -AutoInstall -CreateDefaultTheme
        Automatically installs Oh My Posh and creates a default theme if needed.

    .NOTES
        This is a high-level setup function that orchestrates the complete Oh My Posh setup process.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory = $false)]
        [switch]$AutoInstall,

        [Parameter(Mandatory = $false)]
        [switch]$PromptForInstall,

        [Parameter(Mandatory = $false)]
        [switch]$CreateDefaultTheme,

        [Parameter(Mandatory = $false)]
        [switch]$SkipFontInfo
    )

    Write-Host "`n--[ Oh My Posh Setup" -ForegroundColor Magenta

    ## Check/Install Oh My Posh
    $ohMyPoshInstalled = Get-Command "oh-my-posh" -ErrorAction SilentlyContinue

    if ( -not $ohMyPoshInstalled ) {
        if ( $AutoInstall ) {
            Write-Host "Oh My Posh not found. Installing automatically" -ForegroundColor Yellow
            $installed = Install-OhMyPosh -SkipFontInfo:$SkipFontInfo
            
            if ( -not $installed ) {
                Write-Warning "Failed to install Oh My Posh. Setup cannot continue."
                return $false
            }
        }
        elseif ( $PromptForInstall ) {
            Write-Host "Oh My Posh is not installed." -ForegroundColor Yellow
            $choice = Read-Host "Would you like to install Oh My Posh now? (Y/n)"
            
            if ($choice -eq '' -or $choice -eq 'y' -or $choice -eq 'Y') {
                $installed = Install-OhMyPosh -SkipFontInfo:$SkipFontInfo
                
                if ( -not $installed ) {
                    Write-Warning "Failed to install Oh My Posh. Setup cannot continue."
                    return $false
                }
            }
            else {
                Write-Host "Skipping Oh My Posh installation." -ForegroundColor Yellow
                Write-Host "You can install it later with: Install-OhMyPosh" -ForegroundColor Gray
                return $false
            }
        }
        else {
            Write-Warning "Oh My Posh is not installed."
            Write-Host "Install it with one of these commands:" -ForegroundColor Yellow
            Write-Host "  PowerShell: Install-OhMyPosh" -ForegroundColor Cyan
            Write-Host "  Windows:    winget install JanDeDobbeleer.OhMyPosh" -ForegroundColor Cyan
            Write-Host "  macOS:      brew install jandedobbeleer/oh-my-posh/oh-my-posh" -ForegroundColor Cyan
            Write-Host "  Linux:      curl -s https://ohmyposh.dev/install.sh | bash -s" -ForegroundColor Cyan
            return $false
        }
    }
    else {
        $version = & oh-my-posh version 2>$null
        Write-Host "Oh My Posh is installed (version: $version)" -ForegroundColor Green
    }

    ## Initialize/Validate Theme
    Write-Host ""
    $themeValid = Initialize-OhMyPoshTheme -RepositoryPath $RepositoryPath -CreateDefault:$CreateDefaultTheme

    if ( -not $themeValid ) {
        Write-Warning "Theme validation failed. Oh My Posh may not work correctly."
        return $false
    }

    ## Font Information
    if ( -not $SkipFontInfo ) {
        Write-Host ""
        Write-Host "📝 Next Steps:" -ForegroundColor Cyan
        Write-Host "  1. Install a Nerd Font for proper icon display" -ForegroundColor White
        Write-Host "     - Download: https://www.nerdfonts.com/" -ForegroundColor Gray
        Write-Host "     - Or run: oh-my-posh font install" -ForegroundColor Gray
        Write-Host "  2. Configure your terminal to use the Nerd Font" -ForegroundColor White
        Write-Host "  3. Restart your terminal to see the new prompt" -ForegroundColor White
        Write-Host ""
        Write-Host "Your theme is installed at: $env:USERPROFILE\.config\ohmyposh\theme.omp.json" -ForegroundColor Gray
        Write-Host "   You can customize it independently of this repository." -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Oh My Posh setup completed successfully" -ForegroundColor Green
    return $true
}
