<#
    .SYNOPSIS
    This script finds Azure App Services with specific site extensions installed, such as Datadog.

    .DESCRIPTION
    This script retrieves a list of Azure App Services and checks each one for installed site extensions that match a specified string (default is "Datadog*"). It supports filtering by resource group and allows for parallel processing to speed up the checks.
    This script can be executed as-is, or you can add it to a Powershell profile or module for reuse.

    .PARAMETER ResourceGroup
    The name of the resource group to filter App Services. If not specified, all App Services will be checked.

    .PARAMETER ThrottleLimit
    The number of parallel threads to use for processing. Default is 10.

    .PARAMETER SiteExtensionString
    A full or partial string to match to site extension IDs. Defaults to "Datadog*". This allows you to specify which site extensions you are interested in finding.

    .EXAMPLE
    .\Search-AzSiteExtensionInstalled.ps1 -ResourceGroup "MyResourceGroup" -ThrottleLimit 5 -SiteExtensionString "Datadog*"
#>

## Set params if script is called directly
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false, HelpMessage = "Specify the resource group to filter App Services.")]
    [string]$ResourceGroup,
    [Parameter(Mandatory = $false, HelpMessage = "Number of parallel threads to use for processing.")]
    [int]$ThrottleLimit = 10,
    [Parameter(Mandatory = $false, HelpMessage = "Full or partial string to match to site extension ID. Defaults to 'Datadog*'")]
    [string]$SiteExtensionString = "Datadog*"
)

## Wrap login in a function so it can be added to a profile or module
function Search-AzSiteExtensionInstalled {
    <#
        .SYNOPSIS
        This script finds Azure App Services with specific site extensions installed, such as Datadog.

        .DESCRIPTION
        This script retrieves a list of Azure App Services and checks each one for installed site extensions that match a specified string (default is "Datadog*"). It supports filtering by resource group and allows for parallel processing to speed up the checks.

        .PARAMETER ResourceGroup
        The name of the resource group to filter App Services. If not specified, all App Services will be checked.

        .PARAMETER ThrottleLimit
        The number of parallel threads to use for processing. Default is 10.

        .PARAMETER SiteExtensionString
        A full or partial string to match to site extension IDs. Defaults to "Datadog*". This allows you to specify which site extensions you are interested in finding.

        .EXAMPLE
        .\Search-AzSiteExtensionInstalled.ps1 -ResourceGroup "MyResourceGroup" -ThrottleLimit 5 -SiteExtensionString "Datadog*"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Specify the resource group to filter App Services.")]
        [string]$ResourceGroup,
        [Parameter(Mandatory = $false, HelpMessage = "Number of parallel threads to use for processing.")]
        [int]$ThrottleLimit = 10,
        [Parameter(Mandatory = $false, HelpMessage = "Full or partial string to match to site extension ID. Defaults to 'Datadog*'")]
        [string]$SiteExtensionString = "Datadog*"
    )

    function Get-AppServices {
        <#
            .SYNOPSIS
            List all App Services if no resource group is specified, or list App Services in a specific resource group.

            .DESCRIPTION
            This function retrieves a list of App Services in Azure. If a resource group is specified, it filters the App Services to only those within that resource group. If no resource group is specified, it retrieves all App Services across all resource groups.

            .PARAMETER ResourceGroup
            The name of the resource group to filter App Services. If not specified, all App Services will be retrieved.
        #>
        Param(
            [string]$ResourceGroup
        )

        ## Get all App Services, filtered by resource group if specified
        if ( $ResourceGroup ) {
            Write-Host "Getting list of App Services in resource group '$ResourceGroup' (this can take a while)" -ForegroundColor Cyan
            try {
                return az webapp list --resource-group $ResourceGroup --query "[].{name:name, rg:resourceGroup}" -o json | ConvertFrom-Json
            } catch {
                Write-Error "Failed to retrieve App Services in resource group '$ResourceGroup'"
                exit 1
            }
        ## No resource group specified, get all App Services
        } else {
            Write-Host "Getting list of all App Services" -ForegroundColor Cyan
            try {
                return az webapp list --query "[].{name:name, rg:resourceGroup}" -o json | ConvertFrom-Json
            } catch {
                Write-Error "Failed to retrieve App Services"
                exit 1
            }
        }
    }

    ##############
    # Main logic #
    ##############

    Write-Host "`n[ Searching for App Services with site extensions matching: $($SiteExtensionString) ]`n" -ForegroundColor Magenta

    try {
        $Apps = Get-AppServices -ResourceGroup $ResourceGroup
    } catch {
        Write-Error "Failed to retrieve App Services. Ensure you are logged in to Azure CLI and the resource group exists."
        exit 1
    }

    ## Build flat list of all (App, Slot) pairs
    $AppSlotPairs = @()
    foreach ( $App in $Apps ) {
        ## Add production slot
        $AppSlotPairs += [PSCustomObject]@{ Name = $App.name; ResourceGroup = $App.rg; Slot = "production" }
        ## Add all deployment slots
        $Slots = az webapp deployment slot list --name $App.name --resource-group $App.rg -o json | ConvertFrom-Json
        foreach ( $slot in $Slots ) {
            if ( $slot.name -and $slot.name -ne "production" ) {
                $AppSlotPairs += [PSCustomObject]@{ Name = $App.name; ResourceGroup = $App.rg; Slot = $slot.name }
            }
        }
    }

    Write-Host "`n[ Found $( $AppSlotPairs.Count ) App Service slot(s) to check for site extension: $($SiteExtensionString) ]`n" -ForegroundColor Magenta

    Write-Host "Checking each App Service slot for site extension: $($SiteExtensionString)" -ForegroundColor Cyan
    ## Now scan all (App, Slot) pairs in parallel
    $Found = $AppSlotPairs | ForEach-Object -Parallel {
        $AppName = $_.Name
        $ResourceGroup = $_.ResourceGroup
        $SlotName = $_.Slot
        $SiteExtensionString = $using:SiteExtensionString

        try {
            ## Get correct publishing credentials for each slot
            if ( $SlotName -eq "production" ) {
                $Creds = az webapp deployment list-publishing-credentials --name $AppName --resource-group $ResourceGroup --query "{username:publishingUserName, password:publishingPassword}" -o json | ConvertFrom-Json
                $KuduUrl = "https://$AppName.scm.azurewebsites.net/api/siteextensions"
            } else {
                $Creds = az webapp deployment list-publishing-credentials --name $AppName --resource-group $ResourceGroup --slot $SlotName --query "{username:publishingUserName, password:publishingPassword}" -o json | ConvertFrom-Json
                $KuduUrl = "https://$AppName-$($SlotName).scm.azurewebsites.net/api/siteextensions"
            }

            ## Create auth header for Kudu API
            $Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Creds.username):$($Creds.password)"))

            ## Query Kudu API for installed site extensions
            try {
                $exts = Invoke-RestMethod -Uri $KuduUrl -Headers @{ Authorization = "Basic $Auth" } -ErrorAction Stop
                if ( $exts | Where-Object { $_.id -like "*$SiteExtensionString" } ) {
                    [PSCustomObject]@{
                        Name          = $AppName
                        ResourceGroup = $ResourceGroup
                        Slot          = $SlotName
                    }
                }
            } catch {
                $ErrorResponse = $_.Exception.Response
                if ( $ErrorResponse ) {
                    $StatusCode = $ErrorResponse.StatusCode.value__
                    switch ( $StatusCode ) {
                        401 { Write-Warning "Unauthorized (401) when checking $AppName/$($SlotName): Check publishing credentials or permissions." }
                        403 { Write-Warning "Forbidden (403) when checking $AppName/$($SlotName): Check permissions, access restrictions, or if the site is stopped." }
                        404 { Write-Warning "Not Found (404) when checking $AppName/$($SlotName): The Kudu site or endpoint does not exist." }
                        default { Write-Error "HTTP error $StatusCode when checking $AppName/$($SlotName): $($_.Exception.Message)" }
                    }
                } else {
                    Write-Error "Error checking $AppName/$($SlotName): $($_.Exception.Message)"
                }
            }
        } catch {
            Write-Error "General error checking $AppName/$($SlotName): $($_.Exception.Message)"
        }
    } -ThrottleLimit $ThrottleLimit

    Write-Host "`n[ Results ]`n" -ForegroundColor Magenta
    ## Display results
    if ( $Found ) {
        Write-Host "Found $( $Found.Count ) App Service slot(s) with the site extension:" -ForegroundColor Green
        $Found | Format-Table -AutoSize
    } else {
        Write-Host "No App Services with the site extension found" -ForegroundColor Yellow
    }

    ## Return results if called programmatically
    return $Found
}

## If this script is being run directly, call the function with the provided parameters
if ( $PSCommandPath ) {
    try {
        Search-AzSiteExtensionInstalled @PSBoundParameters
    } catch {
        Write-Error "Error occurred while searching for site extensions: $($_.Exception.Message)"
        exit 1
    }
}

