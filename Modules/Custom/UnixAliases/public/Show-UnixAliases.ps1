function Show-UnixAliases {
    ## Get internal path to aliases
    $AliasesPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Aliases\")

    ## Ensure directory exists
    if ( -not ( Test-Path $AliasesPath ) ) {
        Write-Error "Could not find UnixAliases module's Aliases directory."
        return $false
    }

    ## Find all .ps1 files in aliases path
    $AliasFiles = Get-ChildItem -Path $AliasesPath -Recurse -Filter "*.ps1"

    if ( $AliasFiles.Count -eq 0 ) {
        Write-Error "Could not find any alias files in UnixAliases module's Aliases directory."
        return $false
    }

    ## Array to store discovered aliases
    $DiscoveredAliases = @()

    ## Load & print functions in each .ps1 file
    ForEach ( $AliasFile in $AliasFiles ) {
        Write-Debug "Loading functions from: $($AliasFile.FullName)"

        ## Dot source file to load its contents
        try {
            . $AliasFile.FullName
        }
        catch {
            Write-Error "Failed to load Unix alias functions from path: $($AliasFile.FullName). Details: $($_.Exception.Message)"
            continue
        }

        ## Add function names to discovered aliases array
        Get-Command -CommandType Function | Where-Object { $_.Source -eq $File.FullName } | ForEach-Object {
            $DiscoveredAliases += $_.Name
        }
    }

    if ( $DiscoveredAliases.Count -eq 0 ) {
        Write-Error "Could not find any aliases in UnixAliases module's Aliases directory."
        return $false
    }

    ForEach ( $DiscoveredAlias in $DiscoveredAliases ) {
        Write-Output $DiscoveredAlias
    }

    return $DiscoveredAliases
}
