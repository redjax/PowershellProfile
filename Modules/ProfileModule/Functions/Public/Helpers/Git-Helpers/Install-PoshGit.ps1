
function Install-PoshGit {
    [CmdletBinding()]
    param ()

    ## Ensure TLS 1.2 for secure downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    ## Check if posh-git is already installed
    if (Get-Module -ListAvailable -Name posh-git) {
        Write-Verbose "posh-git is already installed."
        return $true
    }

    ## Ensure NuGet provider is available
    if (-not (Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq 'NuGet' })) {
        try {
            Write-Verbose "Installing NuGet provider..."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "NuGet provider installation failed: $($_.Exception.Message)"
            return $false
        }
    }

    ## Ensure PSGallery is registered and valid
    try {
        $psGallery = Get-PSRepository -ErrorAction Stop | Where-Object { $_.Name -eq 'PSGallery' }

        if (-not $psGallery -or -not $psGallery.SourceLocation) {
            Write-Verbose "PSGallery is missing or broken. Re-registering..."
            Unregister-PSRepository -Name PSGallery -ErrorAction SilentlyContinue

            Register-PSRepository -Name PSGallery `
                -SourceLocation "https://www.powershellgallery.com/api/v2" `
                -InstallationPolicy Trusted `
                -ErrorAction Stop
        }
    }
    catch {
        Write-Warning "Failed to register PSGallery: $($_.Exception.Message)"
        return $false
    }

    ## Try to install posh-git
    try {
        Write-Verbose "Installing posh-git..."
        Install-Module -Name posh-git -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Host "posh-git installed successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Failed to install posh-git: $($_.Exception.Message)"
        return $false
    }
}
