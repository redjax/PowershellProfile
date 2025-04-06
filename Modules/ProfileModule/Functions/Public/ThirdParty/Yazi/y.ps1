function y {
    <#
        .SYNOPSIS
        Function for Yazii
    #>
    if ( Get-Command yazi -ErrorAction SilentlyContinue ) {   
        $tmp = [System.IO.Path]::GetTempFileName()
        
        try {
            yazi $args --cwd-file="$tmp"
        }
        catch {
            Write-Error "Failed to run yazi. Details: $($_.Exception.Message)"
            exit 1
        }

        $cwd = Get-Content -Path $tmp -Encoding UTF8

        if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
            Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
        }

        Remove-Item -Path $tmp
    }
}