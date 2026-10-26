function New-SymLink {
    <#
        .SYNOPSIS
        Creates a symbolic link pointing to an existing file or directory.

        .DESCRIPTION
        Creates a symbolic link at DestPath pointing to SrcPath.

        If DestPath already exists as an ordinary file or directory,
        -Overwrite moves it to DestPath.bak before creating the link.

        Existing symbolic links or junctions are left unchanged.

        An existing backup is never automatically deleted.

        Supports -WhatIf and -Confirm.

        .PARAMETER SrcPath
        Existing file or directory that the symbolic link will point to.

        .PARAMETER DestPath
        Location at which to create the symbolic link.

        Its parent directory must already exist.

        .PARAMETER Overwrite
        Moves an existing ordinary destination to DestPath.bak before
        creating the symbolic link.

        .EXAMPLE
        New-SymLink `
            -SrcPath 'C:\Actual\Config' `
            -DestPath 'C:\Links\Config'

        Creates C:\Links\Config pointing to C:\Actual\Config.

        .EXAMPLE
        New-SymLink `
            -SrcPath 'C:\Actual\Config' `
            -DestPath 'C:\Links\Config' `
            -Overwrite `
            -WhatIf

        Previews backing up the destination and creating the link.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Existing file or directory to link to.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SrcPath,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Location at which to create the symbolic link.'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $DestPath,

        [Parameter(
            HelpMessage = 'Back up an existing destination before creating the link.'
        )]
        [switch] $Overwrite
    )

    try {
        if (
            [string]::IsNullOrWhiteSpace($SrcPath) -or
            [string]::IsNullOrWhiteSpace($DestPath)
        ) {
            throw 'SrcPath and DestPath cannot be empty or whitespace.'
        }

        $sourceItem = Get-Item `
            -LiteralPath $SrcPath `
            -Force `
            -ErrorAction Stop

        if ($sourceItem.PSProvider.Name -ne 'FileSystem') {
            throw 'SrcPath must identify a file-system item.'
        }

        $source = $sourceItem.FullName

        $destinationProvider = $null
        $destinationDrive = $null

        $destination = (
            $ExecutionContext.SessionState.Path.
            GetUnresolvedProviderPathFromPSPath(
                $DestPath,
                [ref] $destinationProvider,
                [ref] $destinationDrive
            )
        )

        if ($destinationProvider.Name -ne 'FileSystem') {
            throw 'DestPath must identify a file-system location.'
        }

        # Normalize trailing separators, but reject a file-system root.
        $destinationRoot = [IO.Path]::GetPathRoot($destination)

        if ($destination -eq $destinationRoot) {
            throw 'DestPath cannot be a file-system root.'
        }

        $destination = $destination.TrimEnd(
            [char[]] @(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            )
        )

        $parentPath = Split-Path -Parent $destination

        if (-not (
                Test-Path -LiteralPath $parentPath -PathType Container
            )) {
            throw "Destination parent directory does not exist: $parentPath"
        }

        # Enumerating the parent also detects dangling links that
        # Test-Path alone may not recognize.
        $existingItem = Get-ChildItem `
            -LiteralPath $parentPath `
            -Force `
            -ErrorAction Stop |
        Where-Object {
            $_.FullName -eq $destination
        } |
        Select-Object -First 1

        if (
            $null -ne $existingItem -and
            ($existingItem.Attributes -band [IO.FileAttributes]::ReparsePoint)
        ) {
            Write-Warning (
                "Destination is already a symbolic link, junction, " +
                "or other reparse point. No changes made: $destination"
            )

            return
        }

        if ($null -ne $existingItem -and -not $Overwrite) {
            Write-Warning (
                "Destination already exists: $destination. " +
                'Use -Overwrite to back it up before creating the link.'
            )

            return
        }

        # Do not move away a directory containing the intended target.
        if (
            $null -ne $existingItem -and
            $existingItem.PSIsContainer
        ) {
            $relativeSource = [IO.Path]::GetRelativePath(
                $destination,
                $source
            )

            $sourceOutsideDestination = (
                [IO.Path]::IsPathRooted($relativeSource) -or
                $relativeSource -eq '..' -or
                $relativeSource.StartsWith('../') -or
                $relativeSource.StartsWith('..\')
            )

            if (-not $sourceOutsideDestination) {
                throw (
                    'SrcPath cannot be the destination directory or ' +
                    'an item inside it.'
                )
            }
        }

        $backupPath = "$destination.bak"

        if ($null -ne $existingItem) {
            $existingBackup = Get-ChildItem `
                -LiteralPath $parentPath `
                -Force `
                -ErrorAction Stop |
            Where-Object {
                $_.FullName -eq $backupPath
            } |
            Select-Object -First 1

            if ($null -ne $existingBackup) {
                throw (
                    "Backup already exists: $backupPath. " +
                    'Move or remove it manually before retrying.'
                )
            }
        }

        $action = "Create symbolic link pointing to '$source'"

        if ($null -ne $existingItem) {
            $action = (
                "Move existing destination to '$backupPath', " +
                "then create symbolic link pointing to '$source'"
            )
        }

        if (-not $PSCmdlet.ShouldProcess($destination, $action)) {
            return
        }

        $backupCreated = $false

        try {
            if ($null -ne $existingItem) {
                Move-Item `
                    -LiteralPath $destination `
                    -Destination $backupPath `
                    -ErrorAction Stop

                $backupCreated = $true

                Write-Verbose "Original destination moved to $backupPath"
            }

            $link = New-Item `
                -Path $destination `
                -ItemType SymbolicLink `
                -Target $source `
                -ErrorAction Stop

            return $link
        }
        catch {
            $creationError = $_

            if ($backupCreated) {
                try {
                    $currentDestination = Get-ChildItem `
                        -LiteralPath $parentPath `
                        -Force `
                        -ErrorAction Stop |
                    Where-Object {
                        $_.FullName -eq $destination
                    } |
                    Select-Object -First 1

                    if ($null -eq $currentDestination) {
                        Move-Item `
                            -LiteralPath $backupPath `
                            -Destination $destination `
                            -ErrorAction Stop

                        Write-Warning (
                            'Link creation failed. The original ' +
                            'destination was restored.'
                        )
                    }
                    else {
                        Write-Warning (
                            'Link creation failed, but the destination ' +
                            'is occupied. The original remains at ' +
                            "'$backupPath'."
                        )
                    }
                }
                catch {
                    Write-Warning (
                        "Could not restore '$backupPath': " +
                        $_.Exception.Message
                    )
                }
            }

            $PSCmdlet.ThrowTerminatingError($creationError)
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
