function Open-YaziHelp {
    try {
        Start-Process "https://yazi-rs.github.io/docs/quick-start"
    }
    catch {
        Write-Error "Failed to open Yazi help page. Details: $($_.Exception.Message)"
        exit 1
    }
}