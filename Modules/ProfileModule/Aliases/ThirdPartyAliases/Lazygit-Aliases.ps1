## lg -> lazygit
if ( Get-Command "lazygit" -ErrorAction SilentlyContinue ) {
    Set-Alias -Name lg -Value lazygit
}
else {
    Remove-Item -Path Alias:lg -ErrorAction SilentlyContinue
}
