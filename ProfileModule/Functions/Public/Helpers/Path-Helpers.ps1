function Get-ParentPath {
    ## Return the parent directory for a given path.
    param(
        [string]$Path
    )

    if (-not ($Path)) {
        Write-Warning "-Path is empty."
        return
    }

    $ParentPath = Split-Path -Path $Path -Parent

    return $ParentPath
}

function Edit-Profile {
    <#
        Open current profile.ps1 in PowerShell ISE
    #>
    param(
        [string]$Editor = "notepad"
    )
    $ProfilePath = $($PROFILE)
    Write-Debug "Editor: $Editor, Profile: $($ProfilePath)"

    if ($host.Name -match 'ise') {
        ## Edit in PowerShell ISE, if available
        $psISE.CurrentPowerShellTab.Files.Add($ProfilePath)
    }
    else {
        ## Edit in Notepad if no PowerShell ISE found
        & $Editor $ProfilePath
    }
}

function New-SymLink {
<#
        .SYNOPSIS
        Create a new junction/symbolic link.

        .PARAMETER SrcPath
        Path to symlink source (the path that will be symlinked to a new location).

        .PARAMETER DestPath
        Path where $SrcPath alias will live.

        .PARAMETER Overwrite
        If $DestPath is a directory/junction already, remove it or back it up before creating link.

        .EXAMPLE
        Create-NewSymLink -SrcPath c:\path\to\src -DestPath c:\path\to\destination [-Overwrite]
    #>
    param(
        [string]$SrcPath,
        [string]$DestPath,
        [switch]$Overwrite
    )

    if (Test-Path -Path $DestPath) {
        ## Config already exists, check if it's a directory or junction
        $Item = Get-Item $DestPath

        ## Check if path is a junction
        if ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Output "Path is already a junction/symlink: $($DestPath)"
            return
        }

        ## Path is a regular directory
        Write-Warning "Path already exists and is not a junction: $($DestPath)."
        if ($Overwrite) {
            Write-Output "-Overwrite detected. Moving path '$($DestPath)' to '$($DestPath).bak' and creating junction."
            if (Test-Path "$($DestPath).bak") {
                Write-Warning "$($DestPath).bak already exists, overwriting."
                Remove-Item "$($DestPath).bak" -Recurse -Force
            }

            try {
                Move-Item "$($DestPath)" "$($DestPath).bak"
            } catch {
                Write-Error "Error moving path '$($DestPath)' to '$($DestPath).bak'. Details: $($_.Exception.Message)"
                return
            }
        } else {
            return
        }
    }

    Write-Output "Creating symlink from '$($SrcPath)' to '$($DestPath)'."
    $SymlinkCommand = "New-Item -Path $($SrcPath) -ItemType SymbolicLink -Target $($DestPath)"

    if (-not (Test-IsAdmin)) {
        Write-Warning "Script is not running as an administrator. Creating symbolic links on Windows requires administrator rights, elevating command."
        try {
            Start-AsAdmin -Command "$($SymlinkCommand)"
        } catch {
            Write-Error "Error creating symlink from '$($SrcPath)' to '$($DestPath)'. Details: $($_.Exception.Message)"
            return
        }
    } else {
        try {
            Invoke-Expression $SymlinkCommand
        } catch {
            Write-Error "Error creating symlink from '$($SrcPath)' to '$($DestPath)'. Details: $($_.Exception.Message)"
            return
        }
    }
}

function Find-File {
    Param(
        [string]$name
    )

    Get-ChildItem `
        -Recurse `
        -Filter "*${name}*" `
        -ErrorAction SilentlyContinue `
        | ForEach-Object {
            $place_path = $_.directory
            Write-Output "${place_path}\${_}"
    }
}
