function Install-AzureCLI {
    if (-not (Test-Command "az")) {
        Write-Host "Installing Azure CLI with winget"
        winget install -e --id Microsoft.AzureCLI
    }
    else {
        Write-Host "Azure CLI appears to already be installed. Skipping installation."
    }
}
