function Install-OhMyPosh {
    [CmdletBinding()]
    Param()

    $DownloadURL = "https://ohmyposh.dev/install.ps1"

    ## Download & execute Oh-My-Posh install script."
    Write-Host "Downloading & installing Oh-My-Posh..." -ForegroundColor Cyan
    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($DownloadURL))
        Write-Host "Oh-My-Posh installed to ~/.local/bin." -ForegroundColor Green
    } catch {
        Write-Error "Error installing Oh-My-Posh. Details: $($_.Exception.Message)"
        return
    }

    ## Add OhMyPosh path to $PATH
    try {
        $EnvValue = "$($env:PATH);$($env:HOME)/Appdata/Local/Programs/oh-my-posh/bin"
        [System.Environment]::SetEnvironmentVariable(Path, "$($EnvValue)", [System.EnvironmentVariableTarget]::$Target)
    }
    catch {
        Write-Error "Unhandled exception setting environment variable. Details: $($_.Exception.Message)"
    }
}
