function Start-Ping {
    <#
        .SYNOPSIS
        Pings a host and displays timestamped results and a final summary.

        .DESCRIPTION
        Sends individual ping attempts to the selected host.

        Use Count 0 to continue until interrupted. Press Ctrl+C to stop.

        Supports -WhatIf and -Confirm before starting the monitoring loop.

        .PARAMETER Target
        Hostname, IP address, or fully qualified domain name to ping.

        .PARAMETER Count
        Number of ping attempts. Defaults to 3.
        Use 0 to continue until interrupted.

        .PARAMETER Sleep
        Seconds to wait between completed attempts. Defaults to 1.

        .EXAMPLE
        Start-Ping -Target 'google.com'

        .EXAMPLE
        Start-Ping -Target 'server1' -Count 5

        .EXAMPLE
        Start-Ping -Target '192.168.1.1' -Count 5 -Sleep 2

        .EXAMPLE
        Start-Ping -t '192.168.1.13' -c 15 -s 5

        .EXAMPLE
        Start-Ping -Target 'server1' -Count 0 -WhatIf
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Hostname, IP address, or FQDN to ping.'
        )]
        [Alias('t')]
        [ValidateNotNullOrEmpty()]
        [string] $Target,

        [Parameter(
            HelpMessage = 'Number of attempts; 0 continues until interrupted.'
        )]
        [Alias('c')]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $Count = 3,

        [Parameter(
            HelpMessage = 'Seconds to wait between completed attempts.'
        )]
        [Alias('s')]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $Sleep = 1
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        throw 'Target cannot be empty or whitespace.'
    }

    $attemptDescription = "$Count attempt(s)"

    if ($Count -eq 0) {
        $attemptDescription = 'continuous attempts until interrupted'
    }

    $action = (
        "Start ping monitoring: $attemptDescription; " +
        "$Sleep second(s) between attempts"
    )

    if (-not $PSCmdlet.ShouldProcess($Target, $action)) {
        return
    }

    Write-Debug "Target: $Target"
    Write-Debug "Count: $Count"
    Write-Debug "Sleep: $Sleep"

    Write-Host (
        "Pinging '$Target': $attemptDescription; " +
        "interval: $Sleep second(s)."
    ) -ForegroundColor Cyan

    $successes = 0L
    $failures = 0L
    $attempts = 0L

    $timer = [Diagnostics.Stopwatch]::StartNew()

    try {
        while ($Count -eq 0 -or $attempts -lt $Count) {
            $attempts++

            $attemptLabel = "($attempts)"

            if ($Count -gt 0) {
                $attemptLabel = "($attempts/$Count)"
            }

            try {
                $pingResult = Test-Connection `
                    -ComputerName $Target `
                    -Count 1 `
                    -Quiet `
                    -ErrorAction Stop

                $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

                if ($pingResult) {
                    $successes++

                    Write-Host (
                        "[$timestamp] [SUCCESS] " +
                        "$attemptLabel Reply from $Target"
                    ) -ForegroundColor Green
                }
                else {
                    $failures++

                    Write-Host (
                        "[$timestamp] [FAILURE] " +
                        "$attemptLabel No reply from $Target"
                    ) -ForegroundColor Red
                }
            }
            catch {
                $failures++

                $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

                Write-Warning (
                    "[$timestamp] $attemptLabel " +
                    "Error pinging '${Target}': " +
                    $_.Exception.Message
                )
            }

            $hasMoreAttempts = $Count -eq 0 -or $attempts -lt $Count

            if ($hasMoreAttempts -and $Sleep -gt 0) {
                Start-Sleep -Seconds $Sleep
            }
        }
    }
    finally {
        $timer.Stop()
        $duration = $timer.Elapsed

        if ($duration.TotalDays -ge 1) {
            $durationText = (
                '{0} day(s) {1:D2}:{2:D2}:{3:D2}' -f
                [int] [Math]::Floor($duration.TotalDays),
                $duration.Hours,
                $duration.Minutes,
                $duration.Seconds
            )
        }
        else {
            $durationText = (
                '{0:D2}:{1:D2}:{2:D2}' -f
                $duration.Hours,
                $duration.Minutes,
                $duration.Seconds
            )
        }

        Write-Host "`n============[ PING RESULTS ]============" `
            -ForegroundColor Yellow

        Write-Host "  Duration: $durationText" -ForegroundColor Yellow
        Write-Host "  Target: $Target" -ForegroundColor Cyan
        Write-Host "  Pings: $attempts" -ForegroundColor Blue
        Write-Host "  Successes: $successes" -ForegroundColor Green
        Write-Host "  Failures: $failures" -ForegroundColor Red

        Write-Host "========================================`n" `
            -ForegroundColor Yellow
    }
}
