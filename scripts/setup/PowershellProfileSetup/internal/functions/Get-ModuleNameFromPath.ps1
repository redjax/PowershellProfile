function Get-ModuleNameFromPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Path to module")]
        [string]$ModulePath
    )

    if ($null -eq $ModulePath) {
        Write-Error "Could not find module path: $ModulePath"
        return $null
    }

    $ModuleName = [System.IO.Path]::GetFileNameWithoutExtension($_)

    $ModuleName
}