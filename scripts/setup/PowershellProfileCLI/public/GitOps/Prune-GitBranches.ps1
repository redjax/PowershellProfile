function Prune-GitBranches {
    <#
        .SYNOPSIS
        Deletes (prunes) any local branches that still exist after being deleted on the remote.

        .DESCRIPTION
        This script checks out the main branch, fetches from the remote, then
        deletes (prunes) any local branches that still exist after being deleted
        on the remote.

        WARNING: This is a destructive script. Make sure you don't need the local
        copy of your branch before pruning.

        .EXAMPLE
        Prune-GitBranches -MainBranch "main"
    #>
    [CmdletBinding(
        ## Support -WhatIf and -Confirm
        SupportsShouldProcess = $True
    )]
    param(
        [string]$MainBranch = "main"
    )

    Write-Host "Pruning local branches that have been deleted on the remote." -ForegroundColor Green

    try {
        git checkout $($MainBranch); `
            git remote update origin --prune; `
            git branch -vv `
        | Select-String -Pattern ": gone]" `
        | ForEach-Object {
            $_.ToString().Trim().Split(" ")[0]
        } `
        | ForEach-Object {
            If ( $PSCmdlet.ShouldProcess(($_)) ) {
                Write-Output "Deleting branch: $($_)"

                try {
                    git branch -D $_
                }
                catch {
                    Write-Error "Error deleting branch '$($_)'. Details: $($_.Exception.Message)"
                    continue
                }
            }
            else {
                Write-Information "Skipping deletion of branch: $($_)"
                continue
            }
        }

        Write-Host "Local branches pruned." -ForegroundColor Green

        exit 0
    }
    catch {
        Write-Warning "Error pruning local branches. Details: $($_.Exception.Message)"
        exit 1
    }
}