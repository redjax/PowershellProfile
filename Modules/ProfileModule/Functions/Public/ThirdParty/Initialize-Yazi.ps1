function y {
    if ( Get-Command yazi -ErrorAction SilentlyContinue ) {   
        $tmp = [System.IO.Path]::GetTempFileName()
        yazi $args --cwd-file="$tmp"
        $cwd = Get-Content -Path $tmp -Encoding UTF8
        if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
            Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
        }
        Remove-Item -Path $tmp
    }
}

function Open-YaziHelp {
    try {
        Start-Process "https://yazi-rs.github.io/docs/quick-start"
    } catch {
        Write-Error "Failed to open Yazi help page. Details: $($_.Exception.Message)"
        exit 1
    }
}