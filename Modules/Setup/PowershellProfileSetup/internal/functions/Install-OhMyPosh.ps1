function Install-OhMyPosh {
    <#
    .SYNOPSIS
        Installs Oh My Posh prompt customization tool.

    .DESCRIPTION
        Installs Oh My Posh for the current platform (Windows, macOS, or Linux).
        Detects the platform and uses the appropriate installation method.

    .PARAMETER Force
        Forces reinstallation even if Oh My Posh is already installed.

    .PARAMETER SkipFontInfo
        Suppresses the Nerd Font installation reminder.

    .EXAMPLE
        Install-OhMyPosh
        Installs Oh My Posh using the default method for the current platform.

    .EXAMPLE
        Install-OhMyPosh -Force
        Reinstalls Oh My Posh even if already installed.

    .NOTES
        Windows: Uses winget or PowerShell installation script
        macOS: Uses Homebrew
        Linux: Uses curl installation script
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$SkipFontInfo
    )

    Write-Host "Checking Oh My Posh installation" -ForegroundColor Cyan

    ## Check if Oh My Posh is already installed
    $ohMyPoshInstalled = Get-Command "oh-my-posh" -ErrorAction SilentlyContinue

    if ( $ohMyPoshInstalled -and -not $Force ) {
        $version = & oh-my-posh version 2>$null
        Write-Host "Oh My Posh is already installed (version: $version)" -ForegroundColor Green
        return $true
    }

    if ($ohMyPoshInstalled -and $Force) {
        Write-Host "Oh My Posh is already installed but -Force was specified. Reinstalling" -ForegroundColor Yellow
    }

    Write-Host "Installing Oh My Posh" -ForegroundColor Yellow

    try {
        ## Detect platform and install accordingly
        if ( $IsWindows -or $PSVersionTable.PSVersion.Major -lt 6 ) {
            ## Windows installation
            Write-Host "Detected Windows platform" -ForegroundColor Gray

            if ( Get-Command "winget" -ErrorAction SilentlyContinue ) {
                Write-Host "Installing via winget" -ForegroundColor Cyan
                winget install JanDeDobbeleer.OhMyPosh -s winget --silent 2>&1 | Out-Null
                
                if ( $LASTEXITCODE -ne 0 ) {
                    Write-Warning "winget installation failed, falling back to PowerShell script"
                    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
                }
            }
            else {
                Write-Host "winget not found. Installing via PowerShell script" -ForegroundColor Cyan
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://ohmyposh.dev/install.ps1'))
            }
        }
        elseif ( $IsMacOS ) {
            ## macOS installation
            Write-Host "Detected macOS platform" -ForegroundColor Gray

            if ( Get-Command "brew" -ErrorAction SilentlyContinue ) {
                Write-Host "Installing via Homebrew" -ForegroundColor Cyan
                brew install jandedobbeleer/oh-my-posh/oh-my-posh
            }
            else {
                Write-Warning "Homebrew not found. Please install Homebrew first: https://brew.sh"
                Write-Host "After installing Homebrew, run: brew install jandedobbeleer/oh-my-posh/oh-my-posh" -ForegroundColor Yellow
                return $false
            }
        }
        elseif ( $IsLinux ) {
            ## Linux installation
            Write-Host "Detected Linux platform" -ForegroundColor Gray
            Write-Host "Installing via curl" -ForegroundColor Cyan
            
            $installScript = Invoke-WebRequest -Uri "https://ohmyposh.dev/install.sh" -UseBasicParsing
            $installScript.Content | bash -s
        }
        else {
            Write-Error "Unable to detect platform. Please install Oh My Posh manually: https://ohmyposh.dev/docs/installation"
            return $false
        }

        ## Verify installation

        ## Note: On Windows, the PATH might not be updated in the current session
        Write-Host "Verifying installation" -ForegroundColor Cyan
        
        ## Refresh PATH for current session (Windows only)
        if ( $IsWindows -or $PSVersionTable.PSVersion.Major -lt 6 ) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        }

        $ohMyPoshInstalled = Get-Command "oh-my-posh" -ErrorAction SilentlyContinue
        
        if ( $ohMyPoshInstalled ) {
            $version = & oh-my-posh version 2>$null
            Write-Host "Oh My Posh installed successfully (version: $version)" -ForegroundColor Green
            
            if ( -not $SkipFontInfo ) {
                Write-Host "`n" -NoNewline
                Write-Host "⚠️  Important: Nerd Font Required" -ForegroundColor Yellow
                Write-Host "   Oh My Posh requires a Nerd Font to display icons correctly." -ForegroundColor Gray
                Write-Host "   Download from: https://www.nerdfonts.com/" -ForegroundColor Cyan
                Write-Host "   Recommended fonts: CascadiaCode NF, FiraCode NF, JetBrainsMono NF" -ForegroundColor Gray
                Write-Host "   Or run: oh-my-posh font install`n" -ForegroundColor Cyan
            }
            
            return $true
        }
        else {
            Write-Warning "Oh My Posh installation completed but command not found."
            Write-Host "You may need to:" -ForegroundColor Yellow
            Write-Host "  1. Restart your terminal" -ForegroundColor White
            Write-Host "  2. Close and reopen PowerShell" -ForegroundColor White
            Write-Host "  3. Check your PATH environment variable" -ForegroundColor White
            return $false
        }
    }
    catch {
        Write-Error "Failed to install Oh My Posh: $($_.Exception.Message)"
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
        return $false
    }
}
