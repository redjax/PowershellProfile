function Start-LocalBranchPrune {
    [CmdletBinding()]
    Param(
        [String]$MainBranch = "main"
    )

    if ( -Not ( Get-Command "git" -ErrorAction SilentlyContinue ) ) {
        Write-Warning "Git command not found. Please ensure Git is installed and available in your PATH."
        return
    }

    Write-Host "Pruning local branches that have been deleted on the remote." -ForegroundColor Green

    try {
        git checkout $($MainBranch); `
            git remote update origin --prune; `
            git branch -vv `
        | Select-String -Pattern ": gone]" `
        | ForEach-Object {
            $_.toString().Trim().Split(" ")[0]
        } `
        | ForEach-Object {
            git branch -D $_ 
        }

        Write-Host "Local branches pruned." -ForegroundColor Green

        return
    }
    catch {
        Write-Warning "Error pruning local branches. Details: $($_.Exception.Message)"
        return
    }
}