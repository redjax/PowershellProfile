function Initialize-OhMyPoshTheme {
    <#
    .SYNOPSIS
        Initializes and validates Oh My Posh theme configuration.

    .DESCRIPTION
        Validates that the Oh My Posh theme file exists and is valid.
        Optionally creates a default theme if one doesn't exist.

    .PARAMETER ThemePath
        Path to the Oh My Posh theme JSON file. If not specified, uses the default
        repository theme location: config/ohmyposh/theme.omp.json

    .PARAMETER RepositoryPath
        Path to the PowerShell profile repository root. Used to locate the default theme.

    .PARAMETER CreateDefault
        If the theme doesn't exist, create a default theme file.

    .EXAMPLE
        Initialize-OhMyPoshTheme -RepositoryPath "C:\repos\PowershellProfile"
        Validates the theme in the default location.

    .EXAMPLE
        Initialize-OhMyPoshTheme -ThemePath "C:\custom\theme.omp.json"
        Validates a theme at a custom location.

    .NOTES
        Requires Oh My Posh to be installed for validation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ThemePath,

        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath = $PSScriptRoot,

        [Parameter(Mandatory = $false)]
        [switch]$CreateDefault
    )

    ## Determine theme path
    if (-not $ThemePath) {
        $ThemePath = Join-Path -Path $RepositoryPath -ChildPath "config\ohmyposh\theme.omp.json"
    }

    Write-Host "Checking Oh My Posh theme configuration..." -ForegroundColor Cyan
    Write-Host "Theme path: $ThemePath" -ForegroundColor Gray

    ## Check if theme file exists
    if (-not (Test-Path -Path $ThemePath)) {
        Write-Warning "Oh My Posh theme not found at: $ThemePath"

        if ($CreateDefault) {
            Write-Host "Creating default theme..." -ForegroundColor Yellow
            
            ## Create directory if it doesn't exist
            $themeDir = Split-Path -Path $ThemePath -Parent
            if (-not (Test-Path -Path $themeDir)) {
                New-Item -Path $themeDir -ItemType Directory -Force | Out-Null
                Write-Host "Created theme directory: $themeDir" -ForegroundColor Gray
            }

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
                $defaultTheme | ConvertTo-Json -Depth 10 | Set-Content -Path $ThemePath -Encoding UTF8
                Write-Host "✓ Created default Oh My Posh theme at: $ThemePath" -ForegroundColor Green
                Write-Host "  You can customize this theme as needed." -ForegroundColor Gray
            }
            catch {
                Write-Error "Failed to create default theme: $($_.Exception.Message)"
                return $false
            }
        }
        else {
            Write-Host "Theme file does not exist. Use -CreateDefault to create one." -ForegroundColor Yellow
            return $false
        }
    }
    else {
        Write-Host "✓ Theme file exists" -ForegroundColor Green
    }

    ## Validate theme if Oh My Posh is installed
    if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
        Write-Host "Validating theme configuration..." -ForegroundColor Cyan
        
        try {
            $validation = & oh-my-posh config validate --config $ThemePath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Theme is valid" -ForegroundColor Green
                return $true
            }
            else {
                Write-Warning "Theme validation failed:"
                Write-Host $validation -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Warning "Could not validate theme: $($_.Exception.Message)"
            Write-Host "The theme file exists but could not be validated." -ForegroundColor Yellow
            return $true  ## Return true since file exists, even if validation failed
        }
    }
    else {
        Write-Host "Oh My Posh is not installed. Skipping validation." -ForegroundColor Yellow
        Write-Host "Install Oh My Posh with: Install-OhMyPosh" -ForegroundColor Gray
        return $true  ## Return true since file exists
    }
}
