function Install-CustomModules {
    [CmdletBinding()]
    Param(
        [Parameter(mandatory = $false, HelpMessage = "Path to the ProfileSetup module")]
        [string]$SetupModulePath,
        [Parameter(mandatory = $false, HelpMessage = "The path to the JSON config file to use for script execution.")]
        [string]$ConfigFile = "config.json",
        [Parameter(mandatory = $false, HelpMessage = "Path to custom modules for installation")]
        [string]$RepoCustomModulesDir,
        [Parameter(mandatory = $false, HelpMessage = "Path to host's custom moduless directory in the `$PROFILE path")]
        [string]$HostCustomPSModulesDir

    )

    [string]$SetupModuleFilename = "PowershellProfileSetup"

    Write-Verbose "`$SetupModulePath=$($SetupModulePath)"
    Write-Verbose "`$RepoCustomModulesDir=$($RepoCustomModulesDir)"
    Write-Verbose "`$HostCustomPSModulesDir=$($HostCustomPSModulesDir)"

    Write-Host "`n--[ Script Setup" -ForegroundColor Blue

    ## Ensure PowershellProfileSetup module is available
    if (-not ( Test-Path $SetupModulePath ) ) {
        Write-Error "PowershellProfileSetup module not found at path: $SetupModulePath"
        return
    }

    ## Ensure there is a .psm1 file at the module path
    if ( -not ( Get-ChildItem "$SetupModulePath" -Filter *.psm1 ) ) {
        Write-Error "Path is not a module directory: $SetupModulePath"
        return
    }

    ## Ensure repository custom Powershell modules are available
    if ( -not ( Test-Path -Path $RepoCustomModulesDir -ErrorAction SilentlyContinue ) ) {
        Write-Error "Repository custom Powershell modules not found at path '$RepoCustomModulesDir'."
        return
    }

    ## Test if Install-CustomModules command is available
    if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
        Write-Debug "Install-CustomModules command is not available. Import module from path: $($SetupModulePath)"
        try {
            Import-Module $SetupModulePath -ErrorAction Stop
        }
        catch {
            Write-Error "Error importing PowershellProfileSetup module. Details: $($_.Exception.Message)"
            return
        }
    }

    ## Check if Install-CustomModules is available after importing ProfileSetup module
    if (-not (Get-Command Install-CustomModules -ErrorAction SilentlyContinue)) {
        Write-Error "Install-CustomModules command is not available after importing module."
        return
    }
    else {
        Write-Debug "Install-CustomModules command is available after importing module."
    }

    ## Import setup module
    Write-Host "Importing PowershellProfileSetup module from: $SetupModulePath" -ForegroundColor Cyan
    try {
        Import-Module $SetupModulePath -Force -Scope Global
        Write-Host "Imported $($SetupModuleFilename) module" -ForegroundColor Green
    }
    catch {
        Write-Error "Error importing PowershellProfileSetup module. Details: $($_.Exception.Message)"
        return
    }

    Write-Host "`n--[ Validate Environment" -ForegroundColor Blue

    ## Initialize custom modules directory
    try {
        Invoke-CustomModulesPathInit -RepoModulesDir $HostCustomPSModulesDir -ErrorAction SilentlyContinue | Out-Null
        $CustomModulesDirCreatedStatus = $true
    }
    catch {
        Write-Error "Error initializing custom Powershell modules path. Details: $($_.Exception.Message)"
        $CustomModulesDirCreatedStatus = $false
    }

    if (-not $CustomModulesDirCreatedStatus) {
        Write-Error "Did not find custom modules directory at path: $HostCustomPSModulesDir."
        return
    }

    Write-Host "Initialized custom modules directory at path: $HostCustomPSModulesDir" -ForegroundColor Green

    Write-Host "`n--[ Get Config" -ForegroundColor Blue

    ## Read repo configuration from config.json (or another file passed with -ConfigFile)
    Write-Host "Reading config from '$($ConfigFile)'" -ForegroundColor Cyan
    try {
        $ProfileConfig = Get-ProfileConfig -ConfigFile "config.json"
        Write-Host "Loaded configuration" -ForegroundColor Green
    }
    catch {
        Write-Error "Error importing profile configuration from file: $($ConfigFile). Details: $($_.Exception.Message)"
        return
    }

    Write-Host "`n--[ Prepare Modules for Installation" -ForegroundColor Blue

    ## Array to store module PSCustomObjects loaded from config file
    [PSCustomObject[]]$ConfigInstallModules = @()
    ## Array to store paths to modules for installation operation
    [string[]]$ModuleInstallPaths = @()

    ## Iterate over custom_modules list from config
    $ProfileConfig.custom_modules | ForEach-Object {
        ## Extract module name
        $ModuleName = $_
        ## Build module install path
        $ModuleFile = Join-Path -Path $RepoCustomModulesDir -ChildPath "$($ModuleName).psm1"
        ## Get path to module's parent dir
        $ModuleParentDir = Join-Path -Path $RepoCustomModulesDir -ChildPath $ModuleName

        ## Build module PSCustomObject
        [PSCustomObject]$ModuleObj = [PSCustomObject]@{
            Name = $ModuleName
            File = $ModuleFile
            Path = $ModuleParentDir
        }

        Write-Debug "Module: $($ModuleObj.Name), Path: $($ModuleObj.Path)"

        ## Append full object to array
        $ConfigInstallModules += $ModuleObj
        ## Append module path to array
        $ModuleInstallPaths += $ModuleObj.Path
    }

    Write-Host "Found $($ConfigInstallModules.Count) custom Powershell modules to install" -ForegroundColor Cyan

    Write-Debug "Module install paths: $($ModuleInstallPaths -join ', ')"

    Write-Host "`n--[ Install Modules" -ForegroundColor Blue

    ForEach ( $SourcePath in $ModuleInstallPaths ) {
        $ModuleName = Split-Path -Leaf $SourcePath

        try {
            ## Validate source path exists before copying
            if ( -not ( Test-Path -Path $SourcePath -ErrorAction SilentlyContinue ) ) {
                Write-Warning "Module source path not found: $SourcePath. Skipping install."
                continue
            }

            ## Destination path for the module in HostCustomPSModulesDir
            $DestinationPath = Join-Path -Path $HostCustomPSModulesDir -ChildPath (Split-Path -Leaf $SourcePath)
            if ( Test-Path -Path $DestinationPath -ErrorAction SilentlyContinue ) {
                Write-Warning "Module '$ModuleName' already installed and will be overwritten."
                Write-Debug "Removing existing module from path '$DestinationPath'"

                try {
                    Remove-Item $DestinationPath -Recurse -Force
                }
                catch {
                    Write-Error "Error removing path '$DestinationPath'. Details: $($_.Exception.Message)"
                    continue
                }
            }

            ## Copy the entire module folder to the destination directory
            try {
                Copy-Item -Path $SourcePath -Destination $DestinationPath -Recurse -Force
            }
            catch {
                Write-Error "Error copying module from '$SourcePath' to '$DestinationPath'. Details: $($_.Exception.Message)"
                continue
            }

            Write-Host "Installed module '$ModuleName' to '$DestinationPath'" -ForegroundColor Green
        }
        catch {
            Write-Error "Error installing module from '$SourcePath'. Details: $_.Exception.Message"
            continue
        }
    }
    

    Write-Host "`n--[ Finished Installing Custom Modules" -ForegroundColor Blue
    Write-Host "Successfully installed custom Powershell modules." -ForegroundColor Green

    return $LASTEXITCODE
}