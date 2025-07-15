function Install-PowerShellGet {
    [CmdletBinding()]
    param ()

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (Get-Module -ListAvailable -Name PowerShellGet) {
        Write-Host "PowerShellGet is already installed." -ForegroundColor Yellow
        return
    }

    try {
        Install-Module -Name PowerShellGet -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Host "PowerShellGet installed successfully." -ForegroundColor Green
        return
    }
    catch {
        Write-Error "Install-Module failed: $($_.Exception.Message)"
        return
    }
}
