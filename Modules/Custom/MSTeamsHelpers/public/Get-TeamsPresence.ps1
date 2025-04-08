function Get-TeamsPresence {
    Param(
        [CmdletBinding()]
        ## Enforce UPN format
        [ValidatePattern("^[^@]+@[^@]+\.[^@]+$")]
        [Parameter(Mandatory = $false, HelpMessage = "Array of usernames to monitor presence (username@domain.tld)")]
        $UPNs = @()
    )

    ## Modules required for this script
    $RequiredModules = @("Microsoft.Graph.Users")

    ## Validate input user IDs
    if ( ( -not ( $UPNs ) ) -or ( $UPNs.Count -eq 0 ) ) {
        Write-Error "-UPNs cannot be `$null, and must have at least 1 user, i.e. -UPNs @('username@domain.tld')"
        exit(1)
    }

    ## Force module cache refresh
    $null = Get-Module -ListAvailable -Refresh

    function Get-TeamsUserPresence {
        <#
        .SYNOPSIS
        Get user's Teams presence
    #>
        param (
            [string]$UPN
        )

        try {
            $user = Get-MgUser -UserId $UPN
            $presence = Get-MgUserPresence -UserId $user.Id
            [PSCustomObject]@{
                UPN          = $UPN
                Availability = $presence.Availability
                Activity     = $presence.Activity
            }
        }
        catch {
            Write-Warning "Failed to get presence for $($UPN): $_"
            [PSCustomObject]@{
                UPN          = $UPN
                Availability = "Error"
                Activity     = "Error"
            }
        }
    }

    ## Check for required modules
    foreach ( $module in $requiredModules ) {
        if ( -not ( Get-Module -ListAvailable -Name $module ) ) {
            Write-Warning "$module not installed. Installing..."
            try {
                Install-Module -Name $module -Scope CurrentUser -AllowClobber -Force
                Write-Host "$module installed successfully." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install $($module): $($_.Exception.Message)"
                exit 1
            }
        }
        else {
            Write-Host "$module is already installed." -ForegroundColor Cyan
        }

        Import-Module $module -Force
    }

    ## Import Microsoft Graph
    Write-Host "Importing Microsoft.Graph modules" -ForegroundColor Cyan
    try {
        Import-Module Microsoft.Graph.Users -Force
    }
    catch {
        Write-Error "Error importing Microsoft.Graph module. Details: $($_.Exception.Message)"
    }

    ## Authenticate to Microsoft Graph
    Write-Host "Authenticating to Microsoft Graph (finish in browser)" -ForegroundColor Cyan
    try {
        Connect-MgGraph -Scopes "Presence.Read.All, User.Read.All" -ErrorAction Stop -NoWelcome
        ## Get current authentication context
        $Context = Get-MgContext

        Write-Debug "Scopes:`n$($Context.Scopes -join ', ')"
    }
    catch {
        Write-Error "Authentication failed: $($_.Exception.Message)"
        exit(1)
    }

    ## Confirm Graph connection
    Write-Debug "Microsoft Graph context:`n$(Get-MgContext | Format-List)"

    ## Check if Presence.Read.All is granted
    if ( -not ( ( $Context.Scopes -contains "Presence.Read.All" ) -and ( $Context.Scopes -contains "User.Read.all" ) ) ) {
        Write-Error "Presence.Read.All and User.Read.All permissions required. Actual scopes: $($Context.Scopes)"
        exit(1)
    }

    ## Get presence for each UPN
    Write-Host "Getting presence for $($upns.Count) UPN(s)" -ForegroundColor Cyan
    $results = foreach ($upn in $upns) {
        try {
            Get-TeamsUserPresence -UPN $upn
        }
        catch {
            Write-Error "Error getting presence for UPN: $($upn). Details: $($_.Exception.Message)"
            continue
        }
    }

    Write-Host "`n--[ Results ]--`nRetrieved $($results.Count) presence(s)." -ForegroundColor Green
    $results | Format-Table -AutoSize
}