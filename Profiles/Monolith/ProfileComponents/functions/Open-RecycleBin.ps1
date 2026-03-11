function Open-RecycleBin {
    <#
        .SYNOPSIS
        Opens the Windows Recycle Bin folder.
        
        .DESCRIPTION
        Opens the Windows Recycle Bin using the shell:RecycleBinFolder shortcut.
        Works on Windows systems to provide quick access to the Recycle Bin in Explorer.
        
        .EXAMPLE
        Open-RecycleBin
        Opens the Recycle Bin in Windows Explorer.
        
        .EXAMPLE
        recycle
        Opens the Recycle Bin using the alias.
    #>
    [CmdletBinding()]
    param()
    
    Start-Process "shell:RecycleBinFolder"
}

## Create alias for convenience
Set-Alias -Name recycle -Value Open-RecycleBin
