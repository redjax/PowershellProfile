function Test-IsAdmin {
    ## Check if the current process is running with elevated privileges (admin rights)
    $isAdmin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    return $isAdmin
}

function Get-PowershellVersion() {
    ## Print Powershell version string
    $PowershellVersion = $PSVersionTable.PSVersion.ToString()

    Write-Host "Powershell version: $PowershellVersion"
}

function Start-StarshipShell() {
    ## Initialize Starship shell
    If ( Get-Command starship ) {
        try {
            Invoke-Expression (&starship init powershell)
        }
        catch {
            ## Show error when verbose logging is enabled
            #  Write-Verbose "The 'starship' command was not found. Skipping initialization." -Verbose
        }
    }
}

## Export functions
# Export-ModuleMember -Function Test-IsAdmin
