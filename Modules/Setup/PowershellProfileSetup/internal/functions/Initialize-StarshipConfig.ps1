function Initialize-StarshipConfig {
    <#
        .SYNOPSIS
        Initialize Starship configuration file.

        .DESCRIPTION
        Copies the selected Starship configuration from the repository's config/starship directory
        to the user's home directory at $HOME/.config/starship.toml.

        .PARAMETER ConfigName
        Name of the Starship config to use (without .toml extension).
        Must correspond to a file in config/starship/{ConfigName}.toml.
        Default: "default"

        .PARAMETER RepositoryPath
        Path to the PowershellProfile repository root.
        If not specified, attempts to auto-detect.

        .EXAMPLE
        Initialize-StarshipConfig -ConfigName "minimal"

        .EXAMPLE
        Initialize-StarshipConfig -ConfigName "fast" -RepositoryPath "C:\scripts\PowershellProfile"

        .NOTES
        This function will:
        1. Check if config/starship/{ConfigName}.toml exists
        2. Create $HOME/.config directory if it doesn't exist
        3. Copy the config file to $HOME/.config/starship.toml
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",

        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath
    )

    Write-Host "Initializing Starship configuration: $ConfigName" -ForegroundColor Cyan

    ## Path to the repository's starship config directory
    if ($RepositoryPath) {
        $RepoRoot = $RepositoryPath
        Write-Debug "Using provided repository path: $RepoRoot"
    }
    else {
        # Auto-detect: Go up 5 levels from this script location
        # internal/functions/ -> internal/ -> PowershellProfileSetup/ -> Setup/ -> Modules/ -> RepoRoot
        $RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
        Write-Debug "Auto-detected repository path: $RepoRoot"
    }
    
    $StarshipConfigDir = Join-Path -Path $RepoRoot -ChildPath "config" | Join-Path -ChildPath "starship"
    $SourceConfigPath = Join-Path -Path $StarshipConfigDir -ChildPath "$ConfigName.toml"
    
    Write-Verbose "Repository root: $RepoRoot"
    Write-Verbose "Starship config directory: $StarshipConfigDir"
    Write-Verbose "Source config path: $SourceConfigPath"

    ## Destination path for starship config
    $UserConfigDir = Join-Path -Path $HOME -ChildPath ".config"
    $DestConfigPath = Join-Path -Path $UserConfigDir -ChildPath "starship.toml"

    ## Validate source config exists
    if (-not (Test-Path -Path $SourceConfigPath)) {
        Write-Error "Starship config file not found: $SourceConfigPath"
        Write-Host "Available configs in $StarshipConfigDir :" -ForegroundColor Yellow
        
        if (Test-Path -Path $StarshipConfigDir) {
            Get-ChildItem -Path $StarshipConfigDir -Filter "*.toml" | ForEach-Object {
                Write-Host "  - $($_.BaseName)" -ForegroundColor Yellow
            }
        }
        
        throw "Starship configuration '$ConfigName' not found"
    }

    ## Create user config directory if it doesn't exist
    if (-not (Test-Path -Path $UserConfigDir)) {
        Write-Host "Creating user config directory: $UserConfigDir" -ForegroundColor Yellow
        try {
            New-Item -ItemType Directory -Path $UserConfigDir -Force | Out-Null
        }
        catch {
            Write-Error "Failed to create config directory. Details: $($_.Exception.Message)"
            throw
        }
    }

    ## Backup existing config if it exists
    if (Test-Path -Path $DestConfigPath) {
        $BackupPath = "$DestConfigPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "Backing up existing Starship config to: $BackupPath" -ForegroundColor Yellow
        try {
            Copy-Item -Path $DestConfigPath -Destination $BackupPath -Force
        }
        catch {
            Write-Warning "Failed to backup existing config. Details: $($_.Exception.Message)"
        }
    }

    ## Copy the selected config to user's config directory
    Write-Host "Copying Starship config from: $SourceConfigPath" -ForegroundColor Cyan
    Write-Host "                          to: $DestConfigPath" -ForegroundColor Cyan
    
    try {
        Copy-Item -Path $SourceConfigPath -Destination $DestConfigPath -Force
        Write-Host "✓ Starship configuration installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to copy Starship config. Details: $($_.Exception.Message)"
        throw
    }

    ## Validate the copied config file
    Write-Host "Validating Starship configuration" -ForegroundColor Cyan
    
    try {
        ## Read the TOML file to ensure it's valid
        $ConfigContent = Get-Content -Path $DestConfigPath -Raw
        
        if ([string]::IsNullOrWhiteSpace($ConfigContent)) {
            throw "Config file is empty"
        }
        
        Write-Host "✓ Configuration file is valid" -ForegroundColor Green
    }
    catch {
        Write-Warning "Config validation failed: $($_.Exception.Message)"
        Write-Host "The config was copied but may have issues. Test with: starship config" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Starship configuration setup complete!" -ForegroundColor Green
    Write-Host "Config location: $DestConfigPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can test your config with:" -ForegroundColor Yellow
    Write-Host "  starship config" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: The prompt will be initialized when you load the Starship profile." -ForegroundColor Gray
}
