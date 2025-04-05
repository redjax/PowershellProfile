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

    $SuccessInstalled = @()
    $FailInstalled = @()

    ## Install custom modules
    foreach ($Module in $Modules) {
        Write-Debug "Installing custom Powershell module: $Module"
        try {
            Install-Module -Name $Module -Path $CustomModulesPath -Force
            $SuccessInstalled += $Module
        }
        catch {
            Write-Error "Error installing custom Powershell module: $Module. Details: $($_.Exception.Message)"
            $FailInstalled += $Module
        }
    }

    Write-Debug "Installed $($SuccessInstalled.Count) custom Powershell modules successfully"
    
    if ( $FailInstalled.Count -gt 0 ) {
        
        ## Append custom modules directory to PSModulePath
        try {
            Set-CustomPSModulesPath -CustomModulesPath $CustomModulesPath
        }
        catch {
            Write-Error "Error setting custom Powershell modules path: $CustomModulesPath. Details: $($_.Exception.Message)"
            return $false
        }
    }

    if ( $FailInstalled.Count -gt 0 ) {
        $FailInstalled | ForEach-Object {
            $ModuleName = Get-ModuleNameFromPath -ModulePath $_
            Write-Error "Failed to install custom Powershell module: $ModuleName"
        }

        return $false
    }

    return $true
}

Export-ModuleMember -Function Install-CustomModules
