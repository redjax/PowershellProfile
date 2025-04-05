function Install-CustomModules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Path where custom Powershell moduless will be installed")]
        [string]$CustomModulesDir = "Custom",
        [Parameter(Mandatory = $false, HelpMessage = "Path to repository's Modules directory")]
        [string]$RepoModulesDir = $PSScriptRoot,
        [Parameter(Mandatory = $false, HelpMessage = "List of modules to install")]
        [string[]]$Modules = @()
    )

    $CustomModulesPath = (Join-Path -Path $RepoModulesDir -ChildPath "$($CustomModulesDir)")

    try {
        New-CustomModulesDir -CustomModulesPath $CustomModulesPath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Error creating custom modules path at path: $CustomModulesPath. Details: $($_.Exception.Message)"
        return $false
    }

    ## Get path to Powershell modules directory
    $PSModulesDir = (Split-Path $PROFILE -Parent)
    Write-Debug "Powershell modules directory: $PSModulesDir"

    ## Build custom modules path str
    $CustomModulesPath = (Join-Path -Path $PSModulesDir -ChildPath "Modules" -AdditionalChildPath "$($CustomModulesDir)")

    Write-Debug "Custom modules path: $CustomModulesPath"

    ## Create custom modules directory
    Write-Debug "Custom Powershell modules path: $CustomModulesPath"
    try {
        New-CustomModulesDir -CustomModulesPath $CustomModulesPath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Error creating custom Powershell modules directory at path: $CustomModulesPath. Details: $($_.Exception.Message)"
        return $false
    }

    ## Get all modules in custom modules directory
    $CustomModules = Get-ChildItem -Path $CustomModulesPath -Filter *.psm1

    $CustomModules | ForEach-Object {
        Write-Output "Installing custom Powershell module: $($_.FullName)"
        # try {
        #     Import-Module -Name $_.FullName -ErrorAction Stop
        #     Write-Output "Installed custom Powershell module: $($_.FullName)"
        # }
        # catch {
        #     Write-Error "Error installing custom Powershell module: $($_.FullName). Details: $($_.Exception.Message)"
        #     return $false
        # }
    }

    return $true
}

Export-ModuleMember -Function Install-CustomModules
