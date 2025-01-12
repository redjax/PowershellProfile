# ProfileModule\Aliases.ps1

## Set alias for Greet-User function
Set-Alias -Name ghu -Value Invoke-Greeting

## Alias network connectivity test
Set-Alias -Name tn -Value Test-NetConnection

## Set an alias for Lock-Machine
Set-Alias -Name lock -Value Lock-Machine

## Set aliases for Start-AsAdmin
Set-Alias -Name su -Value Start-AsAdmin
Set-Alias -Name sudo -Value Start-AsAdmin

## which -> Get-Command
Set-Alias -Name which -Value Get-Command
