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
    Param(
        [string]$file
    )

    '' | Out-File $file -Encoding ASCII
}

function unzip {
    Param(
        [string]$file
    )
    $dirname = (Get-Item $file).Basename

    Write-Output ("Extracting", $file, "to", $dirname)
    
    New-Item -Force -ItemType directory -Path $dirname
    expand-archive $file -OutputPath $dirname -ShowProgress
}