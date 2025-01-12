function Get-OpenIPAddress {
    Param(
        [string]$Network = "192.168.1.1-100",
        [switch]$ResultsInWindow
    )
    Write-Host "Scanning for open IP addresses on network: $Network" -ForegroundColor Cyan
    
    if ( -Not (Get-Command nmap -ErrorAction SilentlyContinue) ) {
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
    
    if ( $ResultsInWindow ) {
        Write-Host "Open IP addresses found (results window will open):" -ForegroundColor Green
        $NmapOutput | ForEach-Object {
            if ( $_ -match "Status: Down" ) {
                ( $_ -split '\s+' )[1]
            }
        } | Out-GridView -Title "Available IP addresses in network [$Network]:"
    }
    else {
        Write-Host "Open IP addresses found:" -ForegroundColor Green
        $NmapOutput | ForEach-Object {
            if ( $_ -match "Status: Down" ) {
                ( $_ -split '\s+' )[1]
            }
        }
    }
}
