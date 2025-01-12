function Invoke-Greeting {
    param(
        [string]$Name = $env:USERNAME
    )
    Write-Host "Hello, $Name!"
}

# function Commented-Function {
    # Write-Host "Example function that is not detected by the manifest update script."
# }

# Export-ModuleMember -Function Greet-User
