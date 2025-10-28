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

#############
# Unix-like #
#############

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
function ll { Get-ChildItem -Force | Format-List }
Set-Alias pwd Get-Location

## Unix-like 'touch'
function touch { param($f); New-Item -ItemType File -Path $f -Force }

## File Viewing and Editing
Set-Alias cat Get-Content
function tac { param($f); $c = Get-Content $f; [array]::Reverse($c); $c }
function tail { param($f); Get-Content -Tail 10 -Path $f }
function tailf { param($f); Get-Content -Wait -Path $f }
function head { param($f, $n = 10); Get-Content $f | Select-Object -First $n }

## System/Process
Set-Alias -Name ps -Value Get-Process
Set-Alias -Name kill -Value Stop-Process
Set-Alias -Name clear -Value Clear-Host
Set-Alias -Name history -Value Get-History

## File Management
Set-Alias rm Remove-Item
Set-Alias mv Move-Item
Set-Alias man Get-Help

## Unix-like 'df' to display disk free space
function df {
    Get-Volume
}

## Unix-like 'export' to set environment variables
function export {
    param(
        [string]$name,
        [string]$value
    )
    Set-Item -Force -Path "env:$name" -Value $value;
}

## Unix-like 'grep' to search for text in files or input
function grep {
    param(
        [string]$regex,
        [string]$dir
    )
    if ($dir) {
        Get-ChildItem $dir | Select-String $regex
        return
    }
    $input | Select-String $regex
}

## Unix-like 'pgrep' to find processes by name
function pgrep {
    param(
        [string]$name
    )
    Get-Process $name
}

## Unix-like 'pkill' to kill processes by name
function pkill {
    param(
        [string]$name
    )
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

## Unix-like 'touch' to create a blank file
function touch {
    ## Create a blank file at $file path
    param(
        [string]$file
    )

    '' | Out-File $file -Encoding ASCII
}

## Unix-like 'unzip' to extract zip files
function unzip {
    param(
        [string]$file
    )
    $dirname = (Get-Item $file).BaseName

    Write-Output ("Extracting", $file, "to", $dirname)

    New-Item -Force -ItemType directory -Path $dirname
    Expand-Archive $file -OutputPath $dirname -ShowProgress
}

## Unix-like 'uptime' to show system uptime
function uptime {
    ## Mimic Unix 'uptime' command in PowerShell

    try {
        $OS = Get-WmiObject Win32_OperatingSystem -ComputerName $env:COMPUTERNAME -ErrorAction Stop
        $Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            LastBoot     = $OS.ConvertToDateTime($OS.LastBootUpTime)
            Uptime       = ([String]$Uptime.Days + " Days " + $Uptime.Hours + " Hours " + $Uptime.Minutes + " Minutes")
        } | Format-Table
 
    }
    catch {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            LastBoot     = "Unable to Connect"
            Uptime       = $_.Exception.Message.Split('.')[0]
        }
 
    }
    finally {
        $null = $OS
        $null = $Uptime
    }
}

## Unix-like 'which' to locate a command
function which {
    param(
        [string]$name
    )
    Get-Command $name | Select-Object -ExpandProperty Definition
}

#################
# Other Aliases #
#################

## lg -> lazygit
if ( Get-Command "lazygit" -ErrorAction SilentlyContinue ) {
    Set-Alias -Name lg -Value lazygit
}
else {
    Remove-Item -Path Alias:lg -ErrorAction SilentlyContinue
}

## bwu -> bw unlock
if ( Get-Command "bw" -ErrorAction SilentlyContinue ) {
    Set-Alias -Name bwu -Value Unlock-BitwardenVault
}
else {
    Remove-Item -Path Alias:bwu -ErrorAction SilentlyContinue
}

## Set paths where wezterm CLI might be installed
$WeztermCLIDirs = @(
    "C:\Program Files\WezTerm",
    "%USERPROFILE%\scoop\apps\wezterm\current",
    "$env:USERPROFILE\scoop\apps\wezterm\current"
)

## If wezterm CLI command is not found, try to find it & set an alias
if ( -not ( Get-Command wezterm -ErrorAction SilentlyContinue ) ) {
    $WezPath = $null

    ## Loop over potential install paths
    foreach ( $WezDir in $WeztermCLIDirs ) {
        ## Test for wezterm.exe
        if ( Test-Path -Path "$WezDir\wezterm.exe" -ErrorAction SilentlyContinue ) {
            ## wezterm.exe found, set $WezPath
            $WezPath = "$WezDir\wezterm.exe"
            break
        }
    }

    Write-Debug "Wezterm CLI bin path: $WezPath"
    if ( $WezPath ) {
        ## $WezPath found, set alias
        Set-Alias -Name wezterm -Value $WezPath
    }
}

function y {
    <#
        .SYNOPSIS
        Alias-like function for yazi

        .DESCRIPTION
        Wrap the yazi command to pass args & handle non-existent directories.
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
