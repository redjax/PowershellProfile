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

function touch ($file) {
    ## Create a blank file at $file path

    '' | Out-File $file -Encoding ASCII
}
