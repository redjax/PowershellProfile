function Show-DiskUsage {
    Get-PSDrive -PSProvider filesystem | Where-Object {
        $_.used -gt 0
    } | Select-Object -Property Root, @{
        Name       = "SizeGB";
        expression = {
            ($_.used + $_.free) / 1GB -as [int]
        }
    },
    @{ Name = "UsedGB"; expression = { ($_.used / 1GB) -as [int] } },
    @{ Name = "FreeGB"; expression = { ($_.free / 1GB) -as [int] } },
    @{ Name = "PctFree"; expression = { [math]::Round(($_.free / ($_.used + $_.free)) * 100, 2) } }
}
