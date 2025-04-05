function Install-CustomModules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Path to repository's Modules directory")]
        [string]$RepoModulesDir = $PSScriptRoot,
        [Parameter(Mandatory = $false, HelpMessage = "List of modules to install")]
        [string[]]$Modules = @(),
        [Parameter(Mandatory = $false, HelpMessage = "Path where custom modules should be installed")]
        [string]$HostCustomModulesPath
    )

    ## Arrays to hold module install success/failure
    $SuccessInstalled = @()
    $FailInstalled = @()

    if ( -not ( Test-Path -Path $HostCustomModulesPath -ErrorAction SilentlyContinue ) ) {
        Write-Warning "Host install path not found: $($HostCustomModulesPath)"

        try {
            New-Item -Path $HostCustomModulesPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Debug "Created custom modules directory: $HostCustomModulesPath"
        }
        catch {
            Write-Error "Error creating custom modules directory: $HostCustomModulesPath. Details: $($_.Exception.Message)"
            return $false
        }
    }

    ## Install custom modules
    foreach ($Module in $Modules) {
        Write-Debug "Installing custom Powershell module: $Module"

        ## Extract module name and target path
        $ModuleName = Split-Path -Path $Module -Leaf
        $TargetPath = Join-Path -Path $HostCustomModulesPath -ChildPath $ModuleName

        if ( Test-Path -Path $TargetPath ) {
            Write-Warning "Module already installed at path and will be overwritten: $TargetPath"
        }

        try {
            ## Copy the entire module directory
            Copy-Item -Path $Module -Destination $TargetPath -Recurse -Force

            ## Track successful installation
            Write-Debug "Successfully installed module: $ModuleName"

            $SuccessInstalled += $Module
        }
        catch {
            ## Track failed installation and log error
            Write-Error "Error installing custom Powershell module: $Module. Details: $($_.Exception.Message)"
            $FailInstalled += $Module
        }
    }

    Write-Debug "Installed $($SuccessInstalled.Count) custom Powershell modules successfully"
    
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
