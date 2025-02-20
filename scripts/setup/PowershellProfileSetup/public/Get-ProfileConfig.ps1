function Get-ProfileConfig {
    Param(
        [Parameter(mandatory = $false, HelpMessage = "The path to the JSON config file to use for script execution.")]
        $ConfigFile = "config.json"
    )
    try {
        $Config = Read-ConfigFile -ProfileConfig $ConfigFile
    }
    catch {
        Write-Error "Error reading configuration from file '$($ConfigFile)'. Details: $($_.Exception.Message)"
        exit 1
    }
    
    return $Config
}