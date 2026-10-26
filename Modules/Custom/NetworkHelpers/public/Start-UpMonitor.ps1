function Start-UpMonitor {
    <#
        .SYNOPSIS
        Continuously checks a website using HTTP HEAD requests.

        .DESCRIPTION
        Displays timestamped HTTP results until interrupted with Ctrl+C.

        Supports -WhatIf and -Confirm before starting the monitoring loop.

        .PARAMETER Site
        HTTP or HTTPS URL to monitor.

        .PARAMETER RequestSleep
        Seconds to wait between completed requests. Defaults to 5.

        .PARAMETER TimeoutSeconds
        Request timeout in seconds. Defaults to 30.

        .EXAMPLE
        Start-UpMonitor

        .EXAMPLE
        Start-UpMonitor -Site 'https://example.com' -RequestSleep 10

        .EXAMPLE
        Start-UpMonitor -Site 'https://example.com' -WhatIf
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            HelpMessage = 'HTTP or HTTPS URL to monitor.'
        )]
        [ValidateNotNullOrEmpty()]
        [uri] $Site = 'https://www.google.com',

        [Parameter(
            HelpMessage = 'Seconds to wait between completed requests.'
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $RequestSleep = 5,

        [Parameter(
            HelpMessage = 'Request timeout in seconds.'
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $TimeoutSeconds = 30
    )

    if (
        -not $Site.IsAbsoluteUri -or
        $Site.Scheme -notin @('http', 'https')
    ) {
        throw 'Site must be an absolute HTTP or HTTPS URL.'
    }

    $action = (
        'Start continuous HTTP HEAD monitoring; ' +
        "$RequestSleep second(s) between requests"
    )

    if (-not $PSCmdlet.ShouldProcess($Site.AbsoluteUri, $action)) {
        return
    }

    Write-Host (
        "Monitoring '$($Site.AbsoluteUri)'. Press Ctrl+C to stop."
    ) -ForegroundColor Cyan

    while ($true) {
        try {
            $response = Invoke-WebRequest `
                -Uri $Site `
                -Method Head `
                -TimeoutSec $TimeoutSeconds `
                -UseBasicParsing `
                -ErrorAction Stop

            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

            Write-Output (
                "[$timestamp] HEAD $($Site.AbsoluteUri): " +
                "HTTP $([int] $response.StatusCode)"
            )
        }
        catch {
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

            Write-Warning (
                "[$timestamp] Request to '$($Site.AbsoluteUri)' failed: " +
                $_.Exception.Message
            )
        }

        Start-Sleep -Seconds $RequestSleep
    }
}
