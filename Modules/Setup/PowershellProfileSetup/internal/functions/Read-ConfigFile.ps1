function Read-ConfigFile {
    <#
        .SYNOPSIS
        Read repository configuration from a JSON file.

        .DESCRIPTION
        Configure the $PROFILE module's behavior by reading settings from a JSON file.

        .PARAMETER ProfileConfig
        Path to a JSON file with settings for this repository.

        .EXAMPLE
        Read-ConfigFile -ProfileConfig "config.json"
    #>
    Param(
        $ProfileConfig = "config.json"
    )

    if ( -Not $ProfileConfig ) {
        throw "Missing input -ProfileConfig, which should be a path to a JSON file with settings for this repository."
    }

    ## Config schema
    $defaultConfig = [PSCustomObject]@{
        profile        = [PSCustomObject]@{
            name = "Default"
        }
        log_level      = "INFO"
        repo           = [PSCustomObject]@{
            author       = "redjax"
            profile_base = "_Base.ps1"
        }
        custom_modules = @()
    }

    if ( -Not ( Test-Path -Path $ProfileConfig -PathType Leaf ) ) {
        Write-Warning "Could not find profile configuration at path: $($ProfileConfig). Creating default config."
    
        try {
            $ConfigJson = $defaultConfig | ConvertTo-Json -Depth 10
            Set-Content -Path $ProfileConfig -Value $ConfigJson
        }
        catch {
            Write-Error "Failed to create default config. Details: $($_.Exception.Message)"
            exit 1
        }
    }

    Write-Debug "Loading profile configuration from: $($ProfileConfig)"
    try {
        $ConfigJson = Get-Content -Path $ProfileConfig -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to load profile configuration from path: $($ProfileConfig). Details: $($_.Exception.Message)"
        exit 1
    }

    Write-Debug "Loaded configuration:"
    Write-Debug ($ConfigJson | ConvertTo-Json -Depth 10)

    ## Create config object
    try {
        $Config = [PSCustomObject]@{
            profile        = [PSCustomObject]@{
                name = $ConfigJson.profile.name
            }
            log_level      = $ConfigJson.log_level
            repo           = [PSCustomObject]@{
                author       = $ConfigJson.repo.author
                profile_base = $ConfigJson.repo.profile_base
            }
            custom_modules = $ConfigJson.custom_modules
        }
    }
    catch {
        Write-Error "Failed to create config object. Details: $($_.Exception.Message)"
        exit 1
    }

    return $Config
}
