function which {
    param(
        [string]$name
    )
    Get-Command $name | Select-Object -ExpandProperty Definition
}

Export-ModuleMember -Function which
