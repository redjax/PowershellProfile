## bwu -> bw unlock
if ( Get-Command "bw" -ErrorAction SilentlyContinue ) {
    Set-Alias -Name bwu -Value Unlock-BitwardenVault
}
else {
    Remove-Item -Path Alias:bwu -ErrorAction SilentlyContinue
}