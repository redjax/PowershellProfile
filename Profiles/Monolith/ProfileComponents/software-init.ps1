<#
    .SYNOPSIS
    Third-party software initialization for Monolith profile.

    .DESCRIPTION
    Initializes third-party software integrations:
    - IntelliShell (AI-powered shell assistance)
#>

###########################
# Software Initialization #
###########################

## IntelliShell
$env:INTELLI_HOME = "$env:APPDATA\IntelliShell\Intelli-Shell\data"
if (Get-Command intelli-shell.exe -ErrorAction SilentlyContinue) {
    $intelliCache = Join-Path $env:USERPROFILE ".intellishell\intellishell.ps1"
    
    # Generate cache if it doesn't exist or is older than intelli-shell executable
    $intelliExe = (Get-Command intelli-shell.exe).Source
    if (-not (Test-Path $intelliCache) -or 
        (Get-Item $intelliCache).LastWriteTime -lt (Get-Item $intelliExe).LastWriteTime) {
        
        $cacheDir = Split-Path $intelliCache -Parent
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        
        intelli-shell.exe init powershell | Out-File -FilePath $intelliCache -Encoding utf8
        Write-Verbose "IntelliShell cache regenerated at: $intelliCache"
    }
    
    # Source the cached init script
    . $intelliCache
    Write-Verbose "IntelliShell initialized from cache."
}

