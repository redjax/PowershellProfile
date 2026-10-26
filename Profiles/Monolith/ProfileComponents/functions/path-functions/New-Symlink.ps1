function New-SymLink {
    <#
        .SYNOPSIS
        Creates a symbolic link pointing to an existing file or directory.

        .DESCRIPTION
        Creates a symbolic link at DestPath pointing to SrcPath.

        Uses Start-AsAdmin to perform the operation with administrator privileges on Windows.

        If DestPath already exists as an ordinary file or directory, -Overwrite moves it to DestPath.bak before creating the link.

        Existing symbolic links, junctions, and other reparse points are left unchanged.

        Existing backups are never automatically deleted.

        If link creation fails after backing up the destination, attempts to restore the original destination.

        Supports -WhatIf and -Confirm.

        .PARAMETER SrcPath
        Existing file or directory that the symbolic link will point to.

        .PARAMETER DestPath
        Location at which to create the symbolic link.

        The parent directory must already exist.

        .PARAMETER Overwrite
        Backs up an existing ordinary destination to DestPath.bak before creating the symbolic link.

        .EXAMPLE
        New-SymLink `
            -SrcPath 'C:\Actual\Config' `
            -DestPath 'C:\Links\Config' `
            -WhatIf

        Previews creating C:\Links\Config pointing to C:\Actual\Config.

        .EXAMPLE
        New-SymLink `
            -SrcPath 'C:\Actual\Config' `
            -DestPath 'C:\Links\Config' `
            -Overwrite `
            -Confirm

        Requests confirmation before backing up an existing destination and creating the symbolic link.
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
            [Environment]::OSVersion.Platform -ne
            [PlatformID]::Win32NT
        ) {
            throw (
                'This version of New-SymLink uses Windows elevation ' +
                'and is supported only on Windows.'
            )
        }

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

        $separators = [char[]] @('\', '/')
        $destinationRoot = [IO.Path]::GetPathRoot($destination)

        $destination = $destination.TrimEnd($separators)

        if (
            [string]::Equals(
                $destination,
                $destinationRoot.TrimEnd($separators),
                [StringComparison]::OrdinalIgnoreCase
            )
        ) {
            throw 'DestPath cannot be a file-system root.'
        }

        $parentPath = Split-Path -Parent $destination

        if (-not (
                Test-Path -LiteralPath $parentPath -PathType Container
            )) {
            throw "Destination parent directory does not exist: $parentPath"
        }

        if (-not (
                Get-Command Start-AsAdmin -ErrorAction SilentlyContinue
            )) {
            throw 'The Start-AsAdmin helper is not available.'
        }

        $action = "Create symbolic link pointing to '$source'"

        if ($Overwrite) {
            $action += (
                "; back up an existing ordinary destination to " +
                "'$destination.bak' if necessary"
            )
        }

        if (-not $PSCmdlet.ShouldProcess($destination, $action)) {
            return
        }

        # Everything that changes the filesystem happens inside this block.
        # Values are passed separately rather than inserted into command text.
        $null = Start-AsAdmin -Command {
            param(
                [string] $Source,
                [string] $Destination,
                [bool] $AllowOverwrite
            )

            $ErrorActionPreference = 'Stop'

            function Get-ExistingEntry {
                param(
                    [string] $Path
                )

                $parent = Split-Path -Parent $Path
                $leaf = Split-Path -Leaf $Path

                # Enumerating the parent also finds dangling links that
                # Test-Path might report as missing.
                Get-ChildItem `
                    -LiteralPath $parent `
                    -Force `
                    -ErrorAction Stop |
                Where-Object { $_.Name -eq $leaf } |
                Select-Object -First 1
            }

            $null = Get-Item `
                -LiteralPath $Source `
                -Force `
                -ErrorAction Stop

            $destinationParent = Split-Path -Parent $Destination

            if (-not (
                    Test-Path -LiteralPath $destinationParent -PathType Container
                )) {
                throw (
                    'Destination parent directory does not exist: ' +
                    $destinationParent
                )
            }

            $existingItem = Get-ExistingEntry -Path $Destination

            if (
                $null -ne $existingItem -and
                ($existingItem.Attributes -band [IO.FileAttributes]::ReparsePoint)
            ) {
                Write-Warning (
                    'Destination is already a symbolic link, junction, ' +
                    "or other reparse point. No changes made: $Destination"
                )

                return
            }

            if ($null -ne $existingItem -and -not $AllowOverwrite) {
                throw (
                    "Destination already exists: $Destination. " +
                    'Use -Overwrite to back it up before creating the link.'
                )
            }

            # Do not move the source itself, or a directory containing it.
            $sourceComparison = $Source.TrimEnd([char[]] @('\', '/'))
            $destinationPrefix = $Destination + '\'

            if (
                [string]::Equals(
                    $sourceComparison,
                    $Destination,
                    [StringComparison]::OrdinalIgnoreCase
                ) -or
                $sourceComparison.StartsWith(
                    $destinationPrefix,
                    [StringComparison]::OrdinalIgnoreCase
                )
            ) {
                throw (
                    'SrcPath cannot be the destination itself or an ' +
                    'item inside the destination directory.'
                )
            }

            $backupPath = "$Destination.bak"

            if (
                $null -ne $existingItem -and
                $null -ne (Get-ExistingEntry -Path $backupPath)
            ) {
                throw (
                    "Backup already exists: $backupPath. " +
                    'Move or remove it manually before retrying.'
                )
            }

            $backupCreated = $false

            try {
                if ($null -ne $existingItem) {
                    Move-Item `
                        -LiteralPath $Destination `
                        -Destination $backupPath `
                        -Confirm:$false `
                        -ErrorAction Stop

                    $backupCreated = $true

                    Write-Host "Original destination backed up to: $backupPath"
                }

                $null = New-Item `
                    -Path $Destination `
                    -ItemType SymbolicLink `
                    -Target $Source `
                    -Confirm:$false `
                    -ErrorAction Stop

                Write-Host (
                    "Created symbolic link: '$Destination' -> '$Source'"
                ) -ForegroundColor Green
            }
            catch {
                $creationError = $_

                if ($backupCreated) {
                    try {
                        $currentDestination = Get-ExistingEntry `
                            -Path $Destination

                        if ($null -eq $currentDestination) {
                            Move-Item `
                                -LiteralPath $backupPath `
                                -Destination $Destination `
                                -Confirm:$false `
                                -ErrorAction Stop

                            Write-Warning (
                                'Link creation failed. The original ' +
                                'destination was restored.'
                            )
                        }
                        else {
                            Write-Warning (
                                'Link creation failed and the destination ' +
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

                throw $creationError
            }
        } -ArgumentList @(
            $source
            $destination
            [bool] $Overwrite.IsPresent
        ) -Wait -Confirm:$false -ErrorAction Stop
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
