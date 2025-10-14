function Initialize-OhMyPoshTheme {
    <#
    .SYNOPSIS
        Initializes and validates Oh My Posh theme configuration.

    .DESCRIPTION
        Installs the Oh My Posh theme to the user's config directory and validates it.
        The theme is installed to ~/.config/ohmyposh/theme.omp.json (or equivalent on Windows).
        Reads config.json to determine which theme template to copy from config/ohmyposh/.

    .PARAMETER RepositoryPath
        Path to the PowerShell profile repository root.

    .PARAMETER CreateDefault
        If the selected theme doesn't exist in the repository, create a default theme file.

    .EXAMPLE
        Initialize-OhMyPoshTheme -RepositoryPath "C:\repos\PowershellProfile"
        Installs the theme specified in config.json from the repository to the user's config directory.

    .EXAMPLE
        Initialize-OhMyPoshTheme -RepositoryPath "C:\repos\PowershellProfile" -CreateDefault
        Creates a default theme if the selected template doesn't exist.

    .NOTES
        Requires Oh My Posh to be installed for validation.
        Theme is installed to: $HOME/.config/ohmyposh/theme.omp.json
        Selected theme is read from config.json: ohmyposh.theme
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory = $false)]
        [switch]$CreateDefault
    )

    ## Read config.json to get selected theme
    $configPath = Join-Path -Path $RepositoryPath -ChildPath "config.json"
    
    if ( -not ( Test-Path -Path $configPath ) ) {
        Write-Error "config.json not found at: $configPath"
        return $false
    }

    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        $selectedTheme = $config.ohmyposh.theme
        
        if (-not $selectedTheme) {
            Write-Warning "No theme specified in config.json (ohmyposh.theme). Using 'default'."
            $selectedTheme = "default"
        }
        
        Write-Host "Selected theme from config.json: $selectedTheme" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Failed to read config.json: $($_.Exception.Message)"
        return $false
    }

    ## Determine paths
    #  Template theme in repository (e.g., config/ohmyposh/default.omp.json)
    $templateThemePath = Join-Path -Path $RepositoryPath -ChildPath "config\ohmyposh\$selectedTheme.omp.json"
    
    #  Installed theme in user's config directory (always named theme.omp.json)
    $configDir = Join-Path -Path $HOME -ChildPath ".config\ohmyposh"
    $installedThemePath = Join-Path -Path $configDir -ChildPath "theme.omp.json"

    Write-Host "Installing Oh My Posh theme configuration" -ForegroundColor Cyan
    Write-Host "  Template: $templateThemePath" -ForegroundColor Gray
    Write-Host "  Install:  $installedThemePath" -ForegroundColor Gray

    ## Create config directory if it doesn't exist
    if ( -not ( Test-Path -Path $configDir ) ) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
        Write-Host "Created config directory: $configDir" -ForegroundColor Gray
    }

    ## Check if template theme exists in repository
    $shouldCreateDefault = $false
    
    if ( Test-Path -Path $templateThemePath ) {
        ## Copy template theme to user's config directory
        Write-Host "Installing theme from repository template" -ForegroundColor Yellow
        try {
            Copy-Item -Path $templateThemePath -Destination $installedThemePath -Force
            Write-Host "✓ Theme installed to: $installedThemePath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install theme: $($_.Exception.Message)"
            return $false
        }
    }
    else {
        Write-Warning "Template theme not found at: $templateThemePath"
        
        if ( $CreateDefault ) {
            $shouldCreateDefault = $true
        }
        else {
            Write-Host "Use -CreateDefault to create a default theme." -ForegroundColor Yellow
            return $false
        }
    }

    ## Create default theme if needed
    if ( $shouldCreateDefault ) {
        Write-Host "Creating default theme" -ForegroundColor Yellow

        ## Create a minimal default theme
        $defaultTheme = @{
            '$schema' = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json'
            version = 2
            final_space = $true
            blocks = @(
                @{
                    type = 'prompt'
                    alignment = 'left'
                    segments = @(
                        @{
                            type = 'path'
                            style = 'plain'
                            foreground = 'blue'
                            template = '{{ .Path }} '
                        },
                        @{
                            type = 'git'
                            style = 'plain'
                            foreground = 'green'
                            template = '{{ .HEAD }} '
                        }
                    )
                }
            )
        }

        try {
            $defaultTheme | ConvertTo-Json -Depth 10 | Set-Content -Path $installedThemePath -Encoding UTF8
            Write-Host "Created default Oh My Posh theme at: $installedThemePath" -ForegroundColor Green
            Write-Host "  You can customize this theme as needed." -ForegroundColor Gray
        }
        catch {
            Write-Error "Failed to create default theme: $($_.Exception.Message)"
            return $false
        }
    }

    ## Validate theme file is valid JSON
    if ( Get-Command "oh-my-posh" -ErrorAction SilentlyContinue ) {
        Write-Host "Validating theme configuration..." -ForegroundColor Cyan
        
        try {
            ## Try to read and parse the JSON to ensure it's valid
            $themeContent = Get-Content -Path $installedThemePath -Raw | ConvertFrom-Json
            
            ## Basic validation: check for required properties
            if ( $themeContent.'$schema' -and $themeContent.version ) {
                Write-Host "Theme is valid" -ForegroundColor Green
                return $true
            }
            else {
                Write-Warning "Theme JSON is valid but may be missing required properties (schema, version)"
                Write-Host "The theme may still work. Try restarting your terminal to test." -ForegroundColor Yellow
                return $true
            }
        }
        catch {
            Write-Warning "Could not parse theme file as valid JSON: $($_.Exception.Message)"
            Write-Host "The theme file may be corrupted. Try reinstalling." -ForegroundColor Yellow
            return $false
        }
    }
    else {
        Write-Host "Oh My Posh is not installed. Skipping validation." -ForegroundColor Yellow
        Write-Host "Install Oh My Posh with: Install-OhMyPosh" -ForegroundColor Gray
        return $true
    }
}
