function Install-Starship {
    <#
    .SYNOPSIS
        Installs Starship cross-shell prompt.

    .DESCRIPTION
        Installs Starship using the appropriate package manager for the current platform:
        - Windows: winget or scoop
        - macOS: Homebrew
        - Linux: curl install script

    .PARAMETER SkipFontInfo
        Skip displaying Nerd Font installation information.

    .EXAMPLE
        Install-Starship
        Installs Starship and displays font installation guidance.

    .NOTES
        Requires appropriate package manager to be installed.
        On Windows, prefers winget over scoop.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$SkipFontInfo
    )

    Write-Host "Installing Starship" -ForegroundColor Cyan

    try {
        if ( $IsWindows -or $env:OS -eq "Windows_NT" ) {
            ## Windows installation
            Write-Host "Detected Windows platform" -ForegroundColor Gray
            
            ## Try winget first
            if ( Get-Command winget -ErrorAction SilentlyContinue ) {
                Write-Host "Installing Starship via winget" -ForegroundColor Yellow
                winget install --id Starship.Starship --source winget --silent --accept-package-agreements --accept-source-agreements
                
                if ( $LASTEXITCODE -eq 0 ) {
                    Write-Host "Starship installed successfully" -ForegroundColor Green
                    
                    ## Refresh PATH
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                }
                else {
                    Write-Error "Winget installation failed with exit code: $LASTEXITCODE"
                    return $false
                }
            }
            ## Fallback to scoop
            elseif ( Get-Command scoop -ErrorAction SilentlyContinue ) {
                Write-Host "Installing Starship via scoop" -ForegroundColor Yellow
                scoop install starship
                
                if ( $LASTEXITCODE -eq 0 ) {
                    Write-Host "Starship installed successfully" -ForegroundColor Green
                }
                else {
                    Write-Error "Scoop installation failed with exit code: $LASTEXITCODE"
                    return $false
                }
            }
            else {
                Write-Error "Neither winget nor scoop found. Please install one of them first."
                Write-Host "Install winget: https://aka.ms/getwinget" -ForegroundColor Yellow
                Write-Host "Install scoop: https://scoop.sh/" -ForegroundColor Yellow
                return $false
            }
        }
        elseif ( $IsMacOS ) {
            ## macOS installation
            Write-Host "Detected macOS platform" -ForegroundColor Gray
            
            if ( Get-Command brew -ErrorAction SilentlyContinue ) {
                Write-Host "Installing Starship via Homebrew" -ForegroundColor Yellow
                brew install starship
                
                if ( $LASTEXITCODE -eq 0 ) {
                    Write-Host "Starship installed successfully" -ForegroundColor Green
                }
                else {
                    Write-Error "Homebrew installation failed with exit code: $LASTEXITCODE"
                    return $false
                }
            }
            else {
                Write-Error "Homebrew not found. Install it first: https://brew.sh/"
                return $false
            }
        }
        elseif ( $IsLinux ) {
            ## Linux installation
            Write-Host "Detected Linux platform" -ForegroundColor Gray
            Write-Host "Installing Starship via install script" -ForegroundColor Yellow
            
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            
            if ( $LASTEXITCODE -eq 0 ) {
                Write-Host "✓ Starship installed successfully" -ForegroundColor Green
            }
            else {
                Write-Error "Installation script failed with exit code: $LASTEXITCODE"
                return $false
            }
        }
        else {
            Write-Error "Unknown platform. Please install Starship manually: https://starship.rs/guide/#%F0%9F%9A%80-installation"
            return $false
        }

        ## Display font information
        if ( -not $SkipFontInfo ) {
            Write-Host ""
            Write-Host "📝 Important: Starship requires a Nerd Font" -ForegroundColor Cyan
            Write-Host "  Download from: https://www.nerdfonts.com/" -ForegroundColor Gray
            Write-Host "  Or install with: scoop install FiraCode-NF (Windows)" -ForegroundColor Gray
            Write-Host "  Then configure your terminal to use the Nerd Font" -ForegroundColor Gray
        }

        return $true
    }
    catch {
        Write-Error "Failed to install Starship: $($_.Exception.Message)"
        return $false
    }
}
