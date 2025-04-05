function Set-CustomPSModulesPath {
    <#
        .SYNOPSIS
        Append custom Powershell modules path to $PSModulePath
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Path to repository's custom Modules directory")]
        [string]$CustomModulesPath
    )

    if ( $null -eq $CustomModulesPath ) {
        Write-Error "Could not find custom modules path: $CustomModulesPath"
        return $false
    }

    Write-Debug "Found custom modules path: $CustomModulesPath"
    if ($env:PSModulePath -notlike "*$CustomModulesDir*") {
        Write-Debug "Adding '$CustomModulesDir' to PSModulePath"
        try {
            $env:PSModulePath += ";$CustomModulesDir"
            Write-Debug "Appended custom modules path to PSModules path var"
            return $true
        }
        catch {
            Write-Error "Error appending custom modules path: $CustomModulesPath. Details: $($_.Exception.Message)"
            return $false
        }
    }
}