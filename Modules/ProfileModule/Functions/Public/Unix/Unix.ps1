function Show-MachineUptime {
    ## Mimic Unix 'uptime' command in PowerShell

    $currentTime = Get-Date -Format "HH:mm:ss"

    # Get system uptime
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        $lastBoot = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
    }
    else {
        $lastBoot = [datetime]::Parse((net statistics workstation | Select-String 'since' | ForEach-Object { $_.ToString() -replace 'Statistics since ', '' }))
    }

    $uptimeSpan = (Get-Date) - $lastBoot

    # Extract uptime components
    $years = [math]::Floor($uptimeSpan.Days / 365)
    $remainingDays = $uptimeSpan.Days % 365
    $months = [math]::Floor($remainingDays / 30)
    $remainingDays %= 30
    $weeks = [math]::Floor($remainingDays / 7)
    $days = $remainingDays % 7
    $hours = $uptimeSpan.Hours
    $minutes = $uptimeSpan.Minutes
    $seconds = $uptimeSpan.Seconds

    # Construct uptime string based on available time units
    $uptimeString = @()
    if ($years -gt 0) { $uptimeString += "$years year" + ($years -gt 1 ? "s" : "") }
    if ($months -gt 0) { $uptimeString += "$months month" + ($months -gt 1 ? "s" : "") }
    if ($weeks -gt 0) { $uptimeString += "$weeks week" + ($weeks -gt 1 ? "s" : "") }
    if ($days -gt 0) { $uptimeString += "$days day" + ($days -gt 1 ? "s" : "") }
    if ($hours -gt 0 -or $minutes -gt 0 -or $seconds -gt 0) {
        $uptimeString += "$hours`:$("{0:D2}" -f $minutes)`:$("{0:D2}" -f $seconds)"
    }

    # Convert array to string
    $uptimeFormatted = $uptimeString -join ", "

    # Get logged-in users
    $users = (query user 2>$null | Measure-Object).Count

    Write-Output "$currentTime up $uptimeFormatted,  $users users"
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
