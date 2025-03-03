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
