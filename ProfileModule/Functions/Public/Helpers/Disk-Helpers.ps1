function Get-DiskUsage {
    Get-PSDrive -PSProvider filesystem | Where-Object {
        $_.used -gt 0
    } | Select-Object -Property Root, @{
        name       = "SizeGB";
        expression = {
            ($_.used + $_.free) / 1GB -as [int]
        }
    },
    @{name = "UsedGB"; expression = { ($_.used / 1GB) -as [int] } },
    @{name = "FreeGB"; expression = { ($_.free / 1GB) -as [int] } },
    @{name = "PctFree"; expression = { [math]::round(($_.free / ($_.used + $_.free)) * 100, 2) } }
}