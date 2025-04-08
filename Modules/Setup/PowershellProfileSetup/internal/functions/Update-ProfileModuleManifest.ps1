function Update-ProfileModuleManifest {
    param(
        [string]$Author,
        [string]$RepoModulesDir = "$(Get-Location)\Modules",
        [string]$ModuleRoot = (Join-Path $RepoModulesDir "ProfileModule"),
        [string]$FunctionsPath = (Join-Path $ModuleRoot "Functions"),
        [string]$AliasesPath = (Join-Path $ModuleRoot "Aliases"),
        [string]$ManifestPath = (Join-Path $ModuleRoot "ProfileModule.psd1"),
        [string]$GUIDFilePath = (Join-Path $ModuleRoot "guid.txt"),
        [string]$AuthorFilePath = (Join-Path $ModuleRoot "author.txt"),
        [string]$VersionFilePath = (Join-Path $ModuleRoot "version.txt")
        # [switch]$Debug,
        # [switch]$Verbose
    )

    Write-Debug "`$RepoModulesDir=$($RepoModulesDir), `$ModuleRoot=$($ModuleRoot), `$ManifestPath=$($ManifestPath)"

    if ($Debug) {
        $DebugPreference = "Continue"
    }
    else {
        $DebugPreference = "SilentlyContinue"
    }

    if ($Verbose) {
        $VerbosePreference = "Continue"
    }
    else {
        $VerbosePreference = "SilentlyContinue"
    }

    Write-Verbose "Author string: $Author"
    Write-Verbose "Module root: $($ModuleRoot)"
    Write-Verbose "Functions path: $($FunctionsPath)"
    Write-Verbose "Aliases path: $($AliasesPath)"
    Write-Verbose "Manifest file path: $($ManifestPath)"
    Write-Verbose "Module GUID file path: $($GUIDFilePath)"
    Write-Verbose "Module author file path: $($AuthorFilePath)"
    Write-Verbose "Module version file path: $($VersionFilePath)"

    ## Generate GUID if it doesn't exist
    if (-not (Test-Path -Path $GUIDFilePath)) {
        Write-Debug "GUID file '$($GUIDFilePath)' does not exist. Generating GUID and saving to file."
        $guid = [guid]::NewGuid().ToString()
        Set-Content -Path $GUIDFilePath -Value $guid
    }
    else {
        Write-Debug "Loading GUID from file: $($GUIDFilePath)"
        $guid = Get-Content -Path $GUIDFilePath
        # $guid = [System.IO.File]::ReadAllText($GUIDFilePath)

        # Write-Host "Loaded GUID file for module from path: $($GUIDFilePath)" -ForegroundColor Green
    }

    ## Save author if provided
    if ($Author) {
        Write-Debug "Saving author '$Author' to path: $($AuthorFilePath)"
        Set-Content -Path $AuthorFilePath -Value $Author
    }
    elseif (-not (Test-Path -Path $AuthorFilePath)) {
        Write-Error "Author not provided and author.txt does not exist."
        exit 1
    }
    else {
        Write-Debug "Loading author from file: $($AuthorFilePath)"
        $Author = Get-Content -Path $AuthorFilePath
        # $Author = [System.IO.File]::ReadAllText($AuthorFilePath)

        # Write-Host "Loaded author file for module from path: $($AuthorFilePath)" -ForegroundColor Green
    }

    ## Set version if it doesn't exist
    if (-not (Test-Path -Path $VersionFilePath)) {
        Write-Debug "Version file not found at path '$($VersionFilePath)'. Saving version '0.1.0' to version file."
        $version = "0.1.0"
        Set-Content -Path $VersionFilePath -Value $version
    }
    else {
        Write-Debug "Loading module version from file '$($VersionFilePath)'."
        $version = Get-Content -Path $VersionFilePath
        # $version = [System.IO.File]::ReadAllText($VersionFilePath)

        # Write-Host "Loaded version file for module from path: $($VersionFilePath)" -ForegroundColor Green
    }

    ## Import existing module manifest if it exists
    if (Test-Path -Path $ManifestPath) {
        Write-Debug "Loading module manifest contents from path '$($ManifestPath)'"
        $manifest = Import-PowerShellDataFile -Path $ManifestPath

        # Write-Host "Imported module manifest from path: $($ManifestPath)" -ForegroundColor Green
    }
    else {
        Write-Debug "Did not find module manifest at path '$($ManifestPath)'. Initializing new manifest."
        $manifest = @{
            RootModule        = "ProfileModule.psm1"
            ModuleVersion     = $version
            GUID              = $guid
            Author            = $Author
            FunctionsToExport = @()
            AliasesToExport   = @()
            CmdletsToExport   = @()
            VariablesToExport = @()
        }
    }

    function Get-FunctionsFromScript {
        param(
            $scriptContent
        )

        $Functions = @()
        # $functionRegex = [regex]'(?ms)^function\s+([^\s{]+)\s*{'
        $functionRegex = [regex]'(?ms)^function\s+([^\s{]+)\s*{'
        $SearchMatches = $functionRegex.Matches($scriptContent)

        foreach ($match in $SearchMatches) {
            ## Check if function is uncommented
            if (-not ($match.Value -match '^\s*#')) {
                # $Functions += $match.Groups[1].Value
            
                # Remove any parentheses from the function name
                $functionName = $match.Groups[1].Value -replace '\(\)', ''
                $Functions += $functionName

                Write-Debug "Found module function: $($functionName)"
            }
        }

        return $Functions
    }

    # Helper function to extract aliases from script content
    function Get-AliasesFromScript {
        param(
            $ScriptContent
        )

        $Aliases = @()
        $aliasRegex = [regex]'(?ms)^\s*Set-Alias\s+-Name\s+(\w+)\s+-Value\s+(\w+)'
        $SearchMatches = $aliasRegex.Matches($ScriptContent)

        foreach ($match in $SearchMatches) {
            ## Check if alias is uncommented
            if (-not ($match.Value -match '^\s*#')) {
                $AliasName = $match.Groups[1].Value
                $Aliases += $AliasName

                Write-Debug "Found module alias: $($AliasName)"
            }
        }

        return $Aliases
    }

    Write-Host "Updating Powershell module at path: $($ModuleRoot)" -ForegroundColor Cyan

    ## Update functions and aliases
    $Functions = @()
    $Aliases = @()

    ## Scan for functions in Public/ directory only
    $PublicFunctionsPath = Join-Path $FunctionsPath "Public"
    if (Test-Path -Path $PublicFunctionsPath -PathType Container) {
        Write-Host "Scanning path '$($PublicFunctionsPath)' for script files with functions." -ForegroundColor Cyan

        $publicScripts = Get-ChildItem -Path $PublicFunctionsPath -Filter *.ps1 -Recurse

        if ($publicScripts) {
            Write-Host "Extracting uncommented functions from public scripts." -ForegroundColor Cyan
    

            foreach ($script in $publicScripts) {
                Write-Debug "Extracting functions from script: $($script.FullName)"
                $scriptContent = Get-Content -Path $script.FullName -Raw
                $Functions += Get-FunctionsFromScript -scriptContent $scriptContent
            }

            # Write-Host "Total functions discovered: $($Functions.Count)" -ForegroundColor Cyan
        }
        else {
            Write-Warning "No functions found in script: $($script.FullName)"
        }
    }

    ## Scan for aliases
    if (Test-Path -Path $AliasesPath -PathType Container) {
        Write-Host "Scanning path '$($AliasesPath)' for alias script files." -ForegroundColor Cyan

        # Retrieve all .ps1 files in the Aliases directory recursively
        $aliasScripts = Get-ChildItem -Path $AliasesPath -Filter *.ps1 -Recurse

        # Process each alias script
        foreach ($aliasScript in $aliasScripts) {
            Write-Verbose "Processing alias script: $($aliasScript.FullName)"

            # Read the contents of the alias script
            $scriptContent = Get-Content -Path $aliasScript.FullName -Raw

            # Extract aliases using the Get-AliasesFromScript function
            $discoveredAliases = Get-AliasesFromScript -scriptContent $scriptContent

            # Log discovered aliases for debugging
            Write-Verbose "Discovered aliases: $($discoveredAliases -join ', ')"

            # Add the discovered aliases to the overall Aliases collection
            $Aliases += $discoveredAliases
        }

        # Deduplicate the aliases to avoid duplicates in the manifest
        $Aliases = $Aliases | Sort-Object -Unique

        Write-Host "Total aliases discovered: $($Aliases.Count)" -ForegroundColor Green
    }
    else {
        Write-Warning "Aliases directory not found at path '$($AliasesPath)'."
    }

    # Ensure these are actual arrays of strings
    $FunctionsArray = @($Functions | ForEach-Object { "'$_'" })
    $AliasesArray = @($Aliases | ForEach-Object { "'$_'" })

    ## Add discovered functions to manifest's FunctionsToExport
    $manifest.FunctionsToExport = $FunctionsArray
    ## Add discovered aliases to manifest's AliasesToExport
    $manifest.AliasesToExport = $AliasesArray

    # Make sure that the RootModule, ModuleVersion, GUID, and Author are populated
    $manifest.RootModule = "ProfileModule.psm1" # You can change this if necessary
    $manifest.ModuleVersion = $version
    $manifest.GUID = $guid
    $manifest.Author = $Author

    Write-Host "Updating module manifest at path '$($ManifestPath)'" -ForegroundColor Magenta
    try {
        ## Save the updated or new manifest
        $manifestContent = @"
@{
    RootModule          = '$($manifest.RootModule)'
    ModuleVersion       = '$($manifest.ModuleVersion)'
    GUID                = '$($manifest.GUID)'
    Author              = '$($manifest.Author)'
    FunctionsToExport   = @($($FunctionsArray -join ', '))
    AliasesToExport     = @($($AliasesArray -join ', '))
    CmdletsToExport     = @()
    VariablesToExport   = @()
}
"@
        # Write-Host "Module manifest: $($manifestContent | ConvertTo-Json -Depth 3)"
        Set-Content -Path $ManifestPath -Value $manifestContent

    }
    catch {
        Write-Error "Error updating module manifest file. Details: $($_.Exception.Message)"
        exit 1
    }

}