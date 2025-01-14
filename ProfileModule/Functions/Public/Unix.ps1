<# 
    .SYNOPSIS
    Alias commands for Unix-like Powershell commands.
#>
function uptime {
    ## Print system uptime

    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem |
        Select-Object @{ EXPRESSION = { $_.ConverttoDateTime($_.lastbootuptime) } } | Format-Table -HideTableHeaders
    }
    else {
        net statistics workstation | Select-String 'since' | ForEach-Object { $_.ToString().Replace('Statistics since ','') }
    }
}

function touch {
    ## Create a blank file at $file path
    param(
        [string]$file
    )

    '' | Out-File $file -Encoding ASCII
}

function unzip {
    param(
        [string]$file
    )
    $dirname = (Get-Item $file).BaseName

    Write-Output ("Extracting",$file,"to",$dirname)

    New-Item -Force -ItemType directory -Path $dirname
    Expand-Archive $file -OutputPath $dirname -ShowProgress
}

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

function df {
    Get-Volume
}

function sed {
    param(
        [string]$file,
        [string]$find,
        [string]$replace
    )
    # (Get-Content $file).Replace("$find",$replace) | Set-Content $file
    [System.IO.File]::ReadAllText("$($file)").Replace("$find", "$replace") | Set-Content $file
}

function which {
    param(
        [string]$name
    )
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export {
    param(
        [string]$name,
        [string]$value
    )
    Set-Item -Force -Path "env:$name" -Value $value;
}

function pkill {
    param(
        [string]$name
    )
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep {
    param(
        [string]$name
    )
    Get-Process $name
}
