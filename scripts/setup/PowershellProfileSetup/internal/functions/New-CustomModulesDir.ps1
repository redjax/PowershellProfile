function New-CustomModulesDir {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Path to custom Powershell modules directory")]
        [string]$CustomModulesPath
    )

    if ( -Not ( Test-Path -Path $CustomModulesPath ) ) {
        Write-Output "Creating custom modules directory: $($CustomModulesPath)"

        try {
            New-Item -Path $CustomModulesPath -ItemType Directory -Force
            Write-Output "Created custom modules directory: $($CustomModulesPath)"
        }
        catch {
            Write-Error "Error creating custom modules directory: $($CustomModulesPath). Details: $($_.Exception.Message)"
            return $False
        }
    }

    return $True
}
