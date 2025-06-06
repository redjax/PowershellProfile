## Alias network connectivity test
Set-Alias -Name tn -Value Test-NetConnection

## Set an alias for Lock-Machine
Set-Alias -Name lock -Value Lock-Machine

## Set aliases for Start-AsAdmin
# Set-Alias -Name su -Value Start-AsAdmin
# Set-Alias -Name sudo -Value Start-AsAdmin

## which -> Get-Command
# Set-Alias -Name which -Value Get-Command

## reload -> Restart-ShellSession
Set-Alias -Name reload -Value Restart-ShellSession

## profiles -> Show-PSProfilePaths
Set-Alias -Name profiles -Value Show-PSProfilePaths

## find -> Find-File
# Set-Alias -Name find -Value Find-File

## lg -> lazygit
Set-Alias -Name lg -Value lazygit

## bwu -> bw unlock
Set-Alias -Name bwu -Value Unlock-BitwardenVault
