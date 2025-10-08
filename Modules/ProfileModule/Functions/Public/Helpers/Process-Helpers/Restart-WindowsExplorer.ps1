function Restart-WindowsExplorer {
    Write-Host "Restarting Windows Explorer..." -ForegroundColor Yellow
    try {
        ## Stop Windows Explorer
        Stop-Process -Name explorer -Force

        ## Start Windows Explorer
        Start-Process explorer.exe
    } catch {
        Write-Error "Failed to restart Windows Explorer: $($_.Exception.Message)"
        throw
    }
}