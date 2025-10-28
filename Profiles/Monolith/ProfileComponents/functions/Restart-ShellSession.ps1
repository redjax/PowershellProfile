function Restart-ShellSession {
    <#
        .SYNOPSIS
        Functions like the unix 'exec $SHELL' command. Reload a terminal session to refresh
        $PROFILE, modules, env vars, etc.
    #>

    ## Determine the correct executable based on PowerShell version
    $PowerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') {
        ## PowerShell 7+ uses pwsh.exe
        "$PSHOME\pwsh.exe"
    }
    else {
        ## Windows PowerShell uses powershell.exe
        "$PSHOME\powershell.exe"
    }

    ## Restart the shell and set the current working directory
    & $PowerShellExe -NoExit -Command "Set-Location -Path '$PWD'"

    ## Exit the current session
    exit
}

Set-Alias -Name reload -Value Restart-ShellSession
