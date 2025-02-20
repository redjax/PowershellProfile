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

    Write-Output ("Extracting", $file, "to", $dirname)

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
    (Get-Content $file).Replace("$find", $replace) | Set-Content $file
    # [System.IO.File]::ReadAllText("$($file)").Replace("$find", "$replace") | Set-Content $file
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
