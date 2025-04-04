function Get-OpenIPAddress {
    param(
        [string]$Network = "192.168.1.1-100",
        [switch]$ResultsInWindow
    )
    Write-Output "Scanning for open IP addresses on network: $Network"

    if (-not (Get-Command nmap -ErrorAction SilentlyContinue)) {
        Write-Error "nmap is not installed. Please install nmap and try again."
        exit 1
    }

    try {
        $NmapOutput = nmap -v -sn -n $Network -oG -
    }
    catch {
        Write-Error "Error running nmap. Details: $($_.Exception.message)"
        exit 1
    }

    if ($ResultsInWindow) {
        Write-Output "Open IP addresses found (results window will open):"
        $NmapOutput | ForEach-Object {
            if ($_ -match "Status: Down") {
                ($_ -split '\s+')[1]
            }
        } | Out-GridView -Title "Available IP addresses in network [$Network]:"
    }
    else {
        Write-Output "Open IP addresses found:"
        $NmapOutput | ForEach-Object {
            if ($_ -match "Status: Down") {
                ($_ -split '\s+')[1]
            }
        }
    }
}

function Get-PublicIP {
    <#
        .SYNOPSIS
        Return your public IP address by making an HTTP request to ifconfig.me/ip.
    #>
    Write-Output "Making request to https://ifconfig.me/ip"
    try {
        (Invoke-WebRequest https://ifconfig.me/ip).Content
    }
    catch {
        Write-Error "Error requesting public IP. Details: $($_.Exception.Message)"
        return $_.Exception
    }
}

function Get-HTTPSiteAvailable {
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "The website to ping/request. Default: https://www.google.com")]
        [string]$Site = "https://www.google.com",
        [Parameter(Mandatory = $false, HelpMessage = "The number of seconds to wait between requests. Default: 5")]
        [int]$Sleep = 5,
        [Parameter(Mandatory = $false, HelpMessage = "The number of requests to make. Default: 0 (infinite)")]
        [int]$Count = 0,
        [Parameter(Mandatory = $false, HelpMessage = "The HTTP method to use. Default: Head")]
        [string]$Method = "Head"
    )

    $Counter = 0
    $SuccessCount = 0
    $FailureCount = 0

    while ( ($Count -eq 0) -or ($Counter -lt $Count) ) {
        try {
            ## Make HTTP request
            $response = Invoke-WebRequest -Uri $Site -Method $Method

            ## Format output with correct counter
            if ($Count -gt 0) {
                $CountStr = "[$($Counter + 1)/$Count]"
            }
            else {
                $CountStr = "[$($Counter + 1)]"
            }

            ## Display result
            Write-Host "$(Get-Date) Ping site '$Site': [$($response.StatusCode): $($response.StatusDescription)]"

            ## Increment successful request counter
            $SuccessCount++
        }
        catch {
            Write-Host "$(Get-Date): Request failed. Error: $($_.Exception.Message)" -ForegroundColor Red

            ## Increment failed request counter
            $FailureCount++
        }
        finally {
            Write-Output "$($CountStr) [Success: $SuccessCount, Failures: $FailureCount]"
        }

        ## Increment counter correctly
        $Counter++

        if ( $Count -eq 0) {
            ## Pause before next request
            Start-Sleep -Seconds $Sleep
        }
        elseif ( $Counter -lt $Count) {
            ## Pause before next request
            Start-Sleep -Seconds $Sleep
        }        
    }

    Write-Output "`nFinished pinging '$($Site)'`nSuccesses: $($SuccessCount), Failures: $($FailureCount)`n"
}

function Start-Ping {
    <#
        .SYNOPSIS
        Ping a target host, IP, or FQDN. Control the number of times to ping, and the number of seconds to wait between pings.

        .PARAMETER Target
        The target hostname, IP, or FQDN to ping.

        .PARAMETER Count
        The number of times to ping. Default: 3, 0 for infinite.

        .PARAMETER Sleep
        The number of seconds to wait between pings. Default: 1

        .EXAMPLE
        Start-Ping -Target "google.com"

        .EXAMPLE
        Start-Ping -Target "server1" -Count 5

        .EXAMPLE
        Start-Ping -Target "192.168.1.1" -Count 5 -Sleep 2
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, HelpMessage = "The target hostname, IP, or FQDN to ping.")]
        [string]$Target,
        [Parameter(Mandatory = $false, HelpMessage = "The number of times to ping. Default: 3, 0 for infinite.")]
        [int]$Count = 3,
        [Parameter(Mandatory = $false, HelpMessage = "The number of seconds to wait between pings. Default: 1")]
        [int]$Sleep = 1
    )

    ## Function to return a formatted timestamp
    function Get-Timestamp {
        return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    ## Function to print results message
    function Show-ResultsMessage {
        Param(
            [Parameter(Mandatory = $false, HelpMessage = "The target hostname, IP, or FQDN to ping.")]
            [string]$Target,
            [Parameter(Mandatory = $false, HelpMessage = "The total number of pings")]
            [int]$TotalPings,
            [Parameter(Mandatory = $false, HelpMessage = "The number of successful pings")]
            [int]$Successes,
            [Parameter(Mandatory = $false, HelpMessage = "The number of failed pings")]
            [int]$Failures
        )

        Write-Host "`n============[ PING RESULTS ]============`n" -ForegroundColor Yellow
        
        Write-Host "  Target: " -NoNewline ; `
            Write-Host "$Target " -ForegroundColor Cyan
        Write-Host "  Pings: " -NoNewline ; 
        Write-Host "$TotalPings" -ForegroundColor Magenta
        Write-Host "  Successes: " -NoNewline ; `
            Write-Host "$Successes" -ForegroundColor Green
        Write-Host "  Failures: " -NoNewline ; `
            Write-Host "$Failures" -ForegroundColor Red

        Write-Host "`n========================================`n" -ForegroundColor Yellow
    }

    Write-Debug "Target: $Target"
    Write-Debug "Count: $Count"
    Write-Debug "Sleep: $Sleep"

    ## Store number of successful and failed pings
    $Successes = 0
    $Failures = 0

    ## Loop incrementor
    $i = 0

    ## Print different message based on inputs
    if ( $Count -gt 0 ) {
        Write-Host "Ping host: " -NoNewline ; `
            Write-Host "$Target" -ForegroundColor Cyan -NoNewline ; `
            Write-Host " ($Count time(s) | sleep duration: $Sleep)" -ForegroundColor Magenta
    }
    else {
        Write-Host "[$(Get-Timestamp)] Ping host: " -NoNewline ; `
            Write-Host "$Target" -ForegroundColor Cyan -NoNewline ; `
            Write-Host " (indefinite | sleep duration: $Sleep)" -ForegroundColor Magenta
    }

    ## Loop pings
    try {
        while ($Count -eq 0 -or $i -lt $Count) {
            ## Increment counter
            $i++

            ## Build ping attempt string based on inputs
            if ($Count -gt 0) {
                $AttemptStr = "($i/$Count)"
            }
            else {
                $AttemptStr = "($i)"
            }

            ## Do ping
            $PingResult = Test-Connection -ComputerName $Target -Count 1 -Quiet

            ## Print success message
            if ($PingResult) {
                Write-Host "[$(Get-Timestamp)]" -NoNewline; `
                    Write-Host " [SUCCESS]" -ForegroundColor Green -NoNewline; `
                    Write-Host " $AttemptStr Reply from " -NoNewline ; 
                Write-Host "$($Target)" -ForegroundColor Cyan

                ## Increment success counter
                $Successes++
            }
            ## Print failure message
            else {
                Write-Host "[$(Get-Timestamp)]" -NoNewline; `
                    Write-Host " [FAILURE]" -ForegroundColor Red -NoNewline; `
                    Write-Host " $AttemptStr No reply from "-NoNewline ; 
                Write-Host "$($Target)" -ForegroundColor Cyan

                ## Increment failure counter
                $Failures++
            }

            if ( $Sleep -gt 0 ) {
                ## Pause for sleep duration
                Start-Sleep -Seconds $Sleep
            }
        }
    }
    catch {
        Write-Host "Error while pinging $Target : $($_.Exception.Message)"
    }
    finally {
        Show-ResultsMessage -Target $Target -TotalPings $i -Successes $Successes -Failures $Failures
    }
}
