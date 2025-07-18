## git-prune -> Start-LocalBranchPrune
if ( Get-Command "git" -ErrorAction SilentlyContinue ) {
    Set-Alias -Name git-prune -Value Start-LocalBranchPrune
}
else {
    Remove-Item -Path Alias:git-prune -ErrorAction SilentlyContinue
}