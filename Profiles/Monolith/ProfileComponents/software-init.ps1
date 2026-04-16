<#
    .SYNOPSIS
    Third-party software initialization for Monolith profile.

    .DESCRIPTION
    Initializes third-party software integrations:
    - IntelliShell (AI-powered shell assistance)
#>

###########################
# Software Initialization #
###########################

## Disable PowerShell's curl alias on Windows 10+
#  If curl is installed with scoop, prefer the scoop alias
$os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
if (
    (($os.CurrentMajorVersionNumber -as [int]) -eq 10 -and ($os.CurrentMinorVersionNumber -as [int]) -eq 0) -or
    (($os.CurrentBuildNumber -as [int]) -ge 10240)
) {
    Remove-Item Alias:curl -ErrorAction SilentlyContinue
}
