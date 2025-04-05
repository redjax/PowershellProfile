function pgrep {
    param(
        [string]$name
    )
    Get-Process $name
}

Export-ModuleMember -Function pgrep
