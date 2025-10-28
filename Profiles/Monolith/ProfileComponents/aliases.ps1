<#
    .SYNOPSIS
    Unix-like aliases and functions for Monolith profile.

    .DESCRIPTION
    Provides Unix-like command aliases and functions for PowerShell:
    - Directory listing (ls, dir, ll)
    - File operations (touch, cat, tac, tail, head)
    - Process management (ps, kill)
    - File management (rm, mv, cp)
    - Help and navigation (man, pwd, clear, history)
#>

###########
# Aliases #
###########

## Unix-like 'ls' with Terminal-Icons support
Remove-Item Alias:ls -ErrorAction SilentlyContinue
function Enable-TerminalIcons {
    if (-not (Get-Module Terminal-Icons)) {
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    }
}

function ls {
    Enable-TerminalIcons
    Get-ChildItem @args
}

## Unix-like 'dir' with Terminal-Icons support
Remove-Item Alias:dir -ErrorAction SilentlyContinue
function dir {
    Enable-TerminalIcons
    Get-ChildItem @args
}

## Unix-like 'll' (long listing)
Function ll { Get-ChildItem -Force | Format-List }
Set-Alias pwd Get-Location

## Unix-like 'touch'
Function touch { param($f); New-Item -ItemType File -Path $f -Force }

## File Viewing and Editing
Set-Alias cat Get-Content
Function tac { param($f); $c = Get-Content $f; [array]::Reverse($c); $c }
Function tail { param($f); Get-Content -Tail 10 -Path $f }
Function tailf { param($f); Get-Content -Wait -Path $f }
Function head { param($f, $n = 10); Get-Content $f | Select-Object -First $n }

## System/Process
Set-Alias ps Get-Process
Set-Alias kill Stop-Process
Set-Alias clear Clear-Host
Set-Alias history Get-History

## File Management
Set-Alias rm Remove-Item
Set-Alias mv Move-Item
Set-Alias man Get-Help
