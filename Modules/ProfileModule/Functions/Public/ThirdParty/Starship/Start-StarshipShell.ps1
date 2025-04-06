function Start-StarshipShell {
    ## Initialize Starship shell
    if (Get-Command starship) {
        try {
            Invoke-Expression (& starship init powershell)
        }
        catch {
            ## Show error when verbose logging is enabled
            #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
        }
    }
}