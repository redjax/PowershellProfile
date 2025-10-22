## Set paths where wezterm CLI might be installed
$WeztermCLIDirs = @(
    "C:\Program Files\WezTerm",
    "%USERPROFILE%\scoop\apps\wezterm\current",
    "$env:USERPROFILE\scoop\apps\wezterm\current"
)

## If wezterm CLI command is not found, try to find it & set an alias
if ( -not ( Test-CommandExists wezterm -ErrorAction SilentlyContinue ) ) {
    $WezPath = $null

    ## Loop over potential install paths
    foreach ( $WezDir in $WeztermCLIDirs ) {
        ## Test for wezterm.exe
        if ( Test-Path -Path "$WezDir\wezterm.exe" -ErrorAction SilentlyContinue ) {
            ## wezterm.exe found, set $WezPath
            $WezPath = "$WezDir\wezterm.exe"
            break
        }
    }

    Write-Debug "Wezterm CLI bin path: $WezPath"
    if ( $WezPath ) {
        ## $WezPath found, set alias
        Set-Alias -Name wezterm -Value $WezPath
    }
}
