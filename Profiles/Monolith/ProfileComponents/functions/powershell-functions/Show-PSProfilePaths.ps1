function Show-PSProfilePaths {
    <#
        .SYNOPSIS
        Show all $PROFILE paths.
    #>

    # $profile | Get-Member -MemberType NoteProperty
    $PROFILE | Get-Member -MemberType NoteProperty | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            Path = $PROFILE.PSObject.Properties[$_.Name].Value
        }
    } | Format-Table -AutoSize
}