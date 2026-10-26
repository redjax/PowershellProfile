function uptime {
    <#
        .SYNOPSIS
        Returns the local computer's uptime.

        .DESCRIPTION
        Uses Get-Uptime to return the computer name, last boot time,
        and a readable uptime duration.

        Requires PowerShell 6 or later.

        .EXAMPLE
        uptime

        .EXAMPLE
        uptime | Format-Table -AutoSize

        .EXAMPLE
        uptime | Select-Object ComputerName, LastBoot, Uptime
    #>

    [CmdletBinding()]
    param()

    try {
        if (-not (
                Get-Command `
                    -Name Get-Uptime `
                    -CommandType Cmdlet `
                    -ErrorAction SilentlyContinue
            )) {
            throw 'This function requires Get-Uptime from PowerShell 6 or later.'
        }

        $lastBoot = Microsoft.PowerShell.Utility\Get-Uptime `
            -Since `
            -ErrorAction Stop

        $duration = Microsoft.PowerShell.Utility\Get-Uptime `
            -ErrorAction Stop

        [PSCustomObject] @{
            ComputerName = [Environment]::MachineName
            LastBoot     = $lastBoot
            Uptime       = (
                '{0} Days {1} Hours {2} Minutes' -f
                $duration.Days,
                $duration.Hours,
                $duration.Minutes
            )
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
