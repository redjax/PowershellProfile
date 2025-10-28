<#
    .SYNOPSIS
    Command existence cache for Monolith profile.

    .DESCRIPTION
    Pre-caches the existence of commonly used external commands to speed up
    subsequent Get-Command checks throughout the profile components.
    
    This file should be sourced first, before other components that check
    for command existence.

    In your other scripts, where you would normally use the Get-Command cmdlet
    to check for a command's existence, you can now reference the global:CommandCache
    hashtable. For example, instead of:
        if (Get-Command starship -ErrorAction SilentlyContinue) { ... }
    use:
        if ($global:CommandCache['starship']) { ... }
#>

#####################
# Command Cache     #
#####################

## Pre-cache command existence checks (speeds up Get-Command calls throughout profile)
## Each Get-Command check can take 10-50ms, so caching them saves significant time
$global:CommandCache = @{}

$commandsToCheck = @(
    'starship'
    'az'
    'azd'
    'syst'
    'intelli-shell.exe'
    'lazygit'
    'bw'
    'wezterm'
    'yazi'
)

foreach ($cmd in $commandsToCheck) {
    $global:CommandCache[$cmd] = $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}
