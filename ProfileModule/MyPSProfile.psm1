## Example function
function Greet-User {
    param(
        [string]$Name = "World"
    )
    Write-Host "Hello, $Name!"
}
