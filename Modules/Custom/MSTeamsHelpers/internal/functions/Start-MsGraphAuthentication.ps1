function Start-MsGraphAuthentication {
    <#
        .SYNOPSIS
        Authenticates to Microsoft Graph and returns the authentication context.

        .DESCRIPTION
        Connects to Microsoft Graph using delegated permissions.

        Supports -WhatIf and -Confirm. When the connection is not performed, no authentication context is returned.

        .PARAMETER Scopes
        Microsoft Graph delegated permissions to request.

        Defaults to Presence.Read.All and User.Read.All.

        .EXAMPLE
        Start-MsGraphAuthentication

        Authenticates using the default scopes and returns the context.

        .EXAMPLE
        Start-MsGraphAuthentication -WhatIf

        Shows the intended operation without authenticating.

        .EXAMPLE
        Start-MsGraphAuthentication -Confirm

        Requests confirmation before authenticating.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            HelpMessage = 'Microsoft Graph delegated permissions to request.'
        )]
        [ValidateNotNullOrEmpty()]
        [string[]] $Scopes = @(
            'Presence.Read.All'
            'User.Read.All'
        )
    )

    $action = (
        'Authenticate using delegated scopes: ' +
        ($Scopes -join ', ')
    )

    if (-not $PSCmdlet.ShouldProcess('Microsoft Graph', $action)) {
        return
    }

    Write-Host 'Authenticating to Microsoft Graph...' `
        -ForegroundColor Cyan

    try {
        Connect-MgGraph `
            -Scopes $Scopes `
            -NoWelcome `
            -ErrorAction Stop

        $context = Get-MgContext -ErrorAction Stop

        if ($null -eq $context) {
            throw 'No authentication context was returned after connecting.'
        }

        Write-Debug "Scopes:`n$($context.Scopes -join ', ')"

        return $context
    }
    catch {
        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
            $_.Exception,
            'MicrosoftGraphAuthenticationFailed',
            [System.Management.Automation.ErrorCategory]::AuthenticationError,
            'Microsoft Graph'
        )

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
}
