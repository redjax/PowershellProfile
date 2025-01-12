function Invoke-Greeting {
    param(
        [string]$Name = $env:USERNAME
    )
    Write-Output "Hello, $Name!"
}

# function Commented-Function {
# Write-Output "Example function that is not detected by the manifest update script."
# }

# Export-ModuleMember -Function Greet-User
