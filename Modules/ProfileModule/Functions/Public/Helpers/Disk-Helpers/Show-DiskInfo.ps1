function Show-DiskInfo {
    try {
        ## Build a hashtable of WMI disk MediaTypes as a fallback
        $wmiDisks = @{}

        ## Get disk type for each disk
        Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_PhysicalDisk | ForEach-Object {
            $type = switch ($_.MediaType) {
                3 { "HDD" }
                4 { "SSD" }
                5 { "SCM" }
                default { "Unknown" }
            }
            $wmiDisks[$_.DeviceID] = $type
        }

        ## Iterate over each drive
        Get-Volume | Where-Object DriveLetter | ForEach-Object {
            $volume = $_
            $partitions = Get-Partition -Volume $volume 2>$null
            $diskInfo = @()

            ## Iterate partitions
            foreach ($partition in $partitions) {
                ## Skip if no DiskNumber
                if ($null -eq $partition.DiskNumber) { continue }

                $disk = Get-Disk -Number $partition.DiskNumber 2>$null
                ## Skip if no Disk
                if ($null -eq $disk) { continue }

                ## Try Get-PhysicalDisk MediaType
                $pdisk = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq $disk.Number }
                $mediaType = $pdisk.MediaType

                ## If blank or Unspecified, try WMI fallback
                if (-not $mediaType -or $mediaType -eq "Unspecified") {
                    $mediaType = $wmiDisks[$disk.Number]
                }

                ## Final formatting
                if ($mediaType -eq "SSD" -and $disk.BusType -eq "NVMe") {
                    $mediaType = "NVMe SSD"
                }
                elseif (-not $mediaType) {
                    $mediaType = "Unknown"
                }

                ## Create custom object & append to disk info array
                $diskInfo += [PSCustomObject]@{
                    FriendlyName = $disk.FriendlyName
                    MediaType    = $mediaType
                    BusType      = $disk.BusType
                }
            }

            ## Create custom object of disk/partition info
            [PSCustomObject]@{
                DriveLetter  = $volume.DriveLetter
                Label        = $volume.FileSystemLabel
                FriendlyName = ($diskInfo.FriendlyName | Where-Object { $_ } | Select-Object -Unique) -join ', '
                MediaType    = ($diskInfo.MediaType | Where-Object { $_ } | Select-Object -Unique) -join ', '
                BusType      = ($diskInfo.BusType | Where-Object { $_ } | Select-Object -Unique) -join ', '
            }
        }
    }
    catch {
        Write-Error "Error gathering disk info: $($_.Exception.Message)"
        return
    }
}
