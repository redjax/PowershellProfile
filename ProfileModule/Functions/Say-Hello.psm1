function Greet-User {
    param(
        [string]$Name = "World"
    )
    Write-Host "Hello, $Name!"
}

# function Commented-Function {
    # Write-Host "Example function that is not detected by the manifest update script."
# }
