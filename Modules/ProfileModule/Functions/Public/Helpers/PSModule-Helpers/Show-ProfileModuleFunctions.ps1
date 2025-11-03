function Show-ProfileModuleFunctions {
    ## Path to custom Powershell modules (updated for auto-discovery structure)
    $CustomModulesPath = Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath "Modules\Custom"
    Write-Debug "Custom modules path: $CustomModulesPath"

    ## Initialize an array of PSCustomObjects for discovered functions
    $DiscoveredFunctions = @()

    ## Get ProfileModule functions
    try {
        $ProfileModuleFunctions = Get-Command -Module ProfileModule -CommandType Function

        ForEach ( $Function in $ProfileModuleFunctions ) {
            $DiscoveredFunctions += [PSCustomObject]@{
                Module   = "ProfileModule"
                Function = $Function.Name
            }
        }
    }
    catch {
        Write-Error "Unable to show ProfileModule functions. Details: $($_.Exception.Message)"
        exit 1
    }

    ## Get custom module functions
    if ( Test-Path -Path $CustomModulesPath -ErrorAction SilentlyContinue ) {
        Write-Debug "Custom modules path exists: $CustomModulesPath"

        try {
            ## Get all currently imported custom modules
            $ImportedModules = Get-Module | Where-Object {
                $_.Path -like "$CustomModulesPath*"
            }

            ## Iterate through each custom module and get its commands
            ForEach ($Module in $ImportedModules) {
                ## Get module functions
                $ModuleFunctions = Get-Command -Module $Module.Name -CommandType Function

                ForEach ($Function in $ModuleFunctions) {
                    $DiscoveredFunctions += [PSCustomObject]@{
                        Module   = $Module.Name
                        Function = $Function.Name
                    }
                }
            }
        }
        catch {
            Write-Error "Unable to show custom module functions. Details: $($_.Exception.Message)"
            continue
        }
    }
    else {
        Write-Warning "Custom modules directory not found at: $CustomModulesPath"
    }

    ## Print discovered functions
    # Write-Output "`nDiscovered Functions:"
    # ForEach ( $Item in $DiscoveredFunctions ) {
    #     Write-Output "Module: $($Item.Module), Function: $($Item.Function)"
    # }

    $DiscoveredFunctions
}