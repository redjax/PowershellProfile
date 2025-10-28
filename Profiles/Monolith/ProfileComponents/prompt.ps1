<#
    .SYNOPSIS
    Prompt initialization for Monolith profile.

    .DESCRIPTION
    Initializes the prompt based on $PromptHandler variable:
    - "starship": Use Starship prompt (cached)
    - "oh-my-posh": Use Oh-My-Posh prompt (cached)
    - "default", "", or $null: Use custom default prompt
    
    Set $PromptHandler before loading this profile to choose your prompt.
#>

###################
# Prompt Handler  #
###################

function Get-CustomPrompt {
    <#
        .SYNOPSIS
        Custom PowerShell prompt using only built-in tools.

        .DESCRIPTION
        Enhanced default prompt with execution time, user info, and directory display.
    #>

    ## Assign Windows Title Text
    $host.ui.RawUI.WindowTitle = "Current Folder: $pwd"

    # Configure current user, current folder and date outputs
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
    $CmdPromptUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Date = Get-Date -Format 'dddd hh:mm:ss tt'

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    # Calculate execution time of last cmd and convert to milliseconds, seconds or minutes
    $LastCommand = Get-History -Count 1
    if ($lastCommand) { 
        $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds 
    }

    if ($RunTime -ge 60) {
        $ts = [timespan]::fromseconds($RunTime)
        $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
        $ElapsedTime = -join ($min, " min ", $sec, " sec")
    }
    else {
        $ElapsedTime = [math]::Round(($RunTime), 2)
        $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
    }

    # Decorate the CMD Prompt
    Write-Host ""
    Write-Host " PS$($PSVersionTable.PSVersion.Major) " -BackgroundColor Blue -ForegroundColor White -NoNewline
    Write-Host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host " USER:$($CmdPromptUser.Name.split("\")[1]) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    
    if ($CmdPromptCurrentFolder -like "*:*") {
        Write-Host " $CmdPromptCurrentFolder " -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    }
    else { 
        Write-Host ".\$CmdPromptCurrentFolder\ " -ForegroundColor White -BackgroundColor DarkGray -NoNewline 
    }

    Write-Host " $date " -ForegroundColor White
    Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "> "
}

## Initialize prompt based on $PromptHandler variable
try {
    switch ($PromptHandler) {
        "starship" {
            # Starship prompt with caching
            if (Get-Command starship -ErrorAction SilentlyContinue) {
                $starshipCache = Join-Path $env:USERPROFILE ".starship\starship.ps1"
                $starshipConfig = Join-Path $env:USERPROFILE ".config\starship.toml"
                
                # Generate cache if it doesn't exist or is older than starship executable or config file
                $starshipExe = (Get-Command starship).Source
                $cacheNeedsUpdate = $false
                
                if (-not (Test-Path $starshipCache)) {
                    $cacheNeedsUpdate = $true
                }
                elseif ((Get-Item $starshipCache).LastWriteTime -lt (Get-Item $starshipExe).LastWriteTime) {
                    $cacheNeedsUpdate = $true
                }
                elseif ((Test-Path $starshipConfig) -and 
                        (Get-Item $starshipCache).LastWriteTime -lt (Get-Item $starshipConfig).LastWriteTime) {
                    $cacheNeedsUpdate = $true
                }
                
                if ($cacheNeedsUpdate) {
                    $cacheDir = Split-Path $starshipCache -Parent
                    if (-not (Test-Path $cacheDir)) {
                        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                    }
                    
                    & starship init powershell | Out-File -FilePath $starshipCache -Encoding utf8
                    Write-Verbose "Starship cache regenerated at: $starshipCache"
                }
                
                # Source the cached init script
                . $starshipCache
                Write-Verbose "Starship prompt initialized from cache."
            }
            else {
                Write-Warning "Starship is not installed. Falling back to default prompt."
                function prompt { Get-CustomPrompt }
            }
        }
        
        "oh-my-posh" {
            # Oh-My-Posh prompt with caching
            if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
                # Use standard Oh-My-Posh theme location
                $ompTheme = Join-Path $env:USERPROFILE ".config\ohmyposh\theme.omp.json"
                
                if (-not (Test-Path $ompTheme)) {
                    Write-Warning "Oh-My-Posh theme not found at: $ompTheme"
                    Write-Warning "Run Install-MonoProfile.ps1 with -Prompt oh-my-posh to install a theme."
                    Write-Warning "Falling back to default prompt."
                    function prompt { Get-CustomPrompt }
                    return
                }
                
                # Cache path (single cache for all themes)
                $ompCache = Join-Path $env:USERPROFILE ".oh-my-posh\oh-my-posh.ps1"
                
                # Generate cache if it doesn't exist or is older than oh-my-posh executable or theme file
                $ompExe = (Get-Command oh-my-posh).Source
                $cacheNeedsUpdate = $false
                
                if (-not (Test-Path $ompCache)) {
                    $cacheNeedsUpdate = $true
                }
                elseif ((Get-Item $ompCache).LastWriteTime -lt (Get-Item $ompExe).LastWriteTime) {
                    $cacheNeedsUpdate = $true
                }
                elseif ((Get-Item $ompCache).LastWriteTime -lt (Get-Item $ompTheme).LastWriteTime) {
                    $cacheNeedsUpdate = $true
                }
                
                if ($cacheNeedsUpdate) {
                    $cacheDir = Split-Path $ompCache -Parent
                    if (-not (Test-Path $cacheDir)) {
                        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                    }
                    
                    # Generate oh-my-posh init with theme
                    oh-my-posh init pwsh --config $ompTheme | Out-File -FilePath $ompCache -Encoding utf8
                    Write-Verbose "Oh-My-Posh cache regenerated"
                }
                
                # Source the cached init script
                . $ompCache
                Write-Verbose "Oh-My-Posh prompt initialized"
            }
            else {
                Write-Warning "Oh-My-Posh is not installed. Falling back to default prompt."
                function prompt { Get-CustomPrompt }
                # Force initial prompt render
                $null = prompt
            }
        }
        
        default {
            # Default custom prompt (also handles "", $null, "default")
            Write-Verbose "Using custom default prompt."
            function prompt { Get-CustomPrompt }
            # Force initial prompt render
            $null = prompt
        }
    }
}
catch {
    Write-Warning "Failed to initialize prompt handler '$PromptHandler': $($_.Exception.Message)"
    Write-Warning "Falling back to default prompt."
    function prompt { Get-CustomPrompt }
    # Force initial prompt render
    $null = prompt
}
