Param(
    $ProfileConfig = "config.json"
)

## Config schema
$defaultConfig = [PSCustomObject]@{
    profile   = [PSCustomObject]@{
        name = "Default"
    }
    log_level = "INFO"
}

function Get-ConfigObject {
    Param(
        $ProfileConfig = "config.json"
    )
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

    Write-Host "Loading profile configuration from: $($ProfileConfig)" -ForegroundColor Cyan
    try {
        $ConfigJson = Get-Content -Path $ProfileConfig -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to load profile configuration from path: $($ProfileConfig). Details: $($_.Exception.Message)"
        exit 1
    }

    Write-Host "Loaded configuration:" -ForegroundColor Magenta
    Write-Host ($ConfigJson | ConvertTo-Json -Depth 10)

    ## Create config object
    try {
        $Config = [PSCustomObject]@{
            profile   = [PSCustomObject]@{
                name = $ConfigJson.profile.name
            }
            log_level = $ConfigJson.log_level
        }
    }
    catch {
        Write-Error "Failed to create config object. Details: $($_.Exception.Message)"
        exit 1
    }

    return $Config
}

## Initialize configuration object
try {
    $Config = Get-ConfigObject
    Write-Host "Created config object:" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create config object. Details: $($_.Exception.Message)"
    exit 1
}
