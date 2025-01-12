function Install-Winget {
    $WingetIsInstalled = Test-Command -CommandName "winget"

    If ( -Not $WingetIsInstalled ) {
        Write-Host "Installing Winget using Add-AppxPackage"
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    }
    else {
        Write-Host "Winget is already installed"
    }
}
