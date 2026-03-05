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
    $CmdPromptCurrentFolder = $pwd.Path
    $Date = Get-Date -Format 'dddd hh:mm:ss tt'

    # Cache identity info (these don't change during a session)
    if (-not $script:_cachedIdentity) {
        $script:_cachedIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $script:_cachedIsAdmin = (New-Object Security.Principal.WindowsPrincipal ($script:_cachedIdentity)).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        $script:_cachedUserName = $script:_cachedIdentity.Name.split("\")[1]
    }

    # Calculate execution time of last cmd and convert to milliseconds, seconds or minutes
    $LastCommand = Get-History -Count 1
    if ($lastCommand) { 
        $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds 
    }
    else {
        $RunTime = 0
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
    Write-Host ($(if ($script:_cachedIsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host " USER:$($script:_cachedUserName) " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
    Write-Host " $CmdPromptCurrentFolder\ " -ForegroundColor White -BackgroundColor DarkGray -NoNewline

    Write-Host " $date " -ForegroundColor White
    Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "> "
}

## Initialize prompt based on $PromptHandler variable
## Cache-first approach: check for cached init script before falling back to Get-Command
## This avoids expensive PATH scans (~150ms+ with 76 PATH entries)
try {
    switch ($PromptHandler) {
        "starship" {
            $starshipCache = Join-Path $env:USERPROFILE ".starship\starship.ps1"
            $starshipConfig = Join-Path $env:USERPROFILE ".config\starship.toml"

            # Fast path: if cache exists and config hasn't changed, just source it
            if ((Test-Path $starshipCache) -and
                (-not (Test-Path $starshipConfig) -or
                 (Get-Item $starshipCache).LastWriteTime -ge (Get-Item $starshipConfig).LastWriteTime)) {
                . $starshipCache
                Write-Verbose "Starship prompt initialized from cache."
            }
            elseif (Get-Command starship -ErrorAction SilentlyContinue) {
                # Cache is stale or missing - regenerate
                $cacheDir = Split-Path $starshipCache -Parent
                if (-not (Test-Path $cacheDir)) {
                    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                }

                & starship init powershell | Out-File -FilePath $starshipCache -Encoding utf8
                . $starshipCache
                Write-Verbose "Starship cache regenerated and loaded."
            }
            else {
                # Starship not installed - fall back to default prompt
                function global:prompt { Get-CustomPrompt }
            }
        }
        
        "oh-my-posh" {
            $ompTheme = Join-Path $env:USERPROFILE ".config\ohmyposh\theme.omp.json"
            $ompCache = Join-Path $env:USERPROFILE ".oh-my-posh\oh-my-posh.ps1"

            if (-not (Test-Path $ompTheme)) {
                # Theme not found - fall back to default prompt
                function global:prompt { Get-CustomPrompt }
            }
            elseif ((Test-Path $ompCache) -and
                    (Get-Item $ompCache).LastWriteTime -ge (Get-Item $ompTheme).LastWriteTime) {
                # Fast path: cache is fresh
                . $ompCache
                Write-Verbose "Oh-My-Posh prompt initialized from cache."
            }
            elseif (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
                # Cache is stale or missing - regenerate
                $cacheDir = Split-Path $ompCache -Parent
                if (-not (Test-Path $cacheDir)) {
                    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
                }

                oh-my-posh init pwsh --config $ompTheme | Out-File -FilePath $ompCache -Encoding utf8
                . $ompCache
                Write-Verbose "Oh-My-Posh cache regenerated and loaded."
            }
            else {
                # Oh-My-Posh not installed - fall back to default prompt
                function global:prompt { Get-CustomPrompt }
            }
        }
        
        default {
            # Default custom prompt (also handles "", $null, "default")
            Write-Verbose "Using custom default prompt."
            function global:prompt { Get-CustomPrompt }
        }
    }
}
catch {
    Write-Warning "Failed to initialize prompt handler '$PromptHandler': $($_.Exception.Message)"
    Write-Warning "Falling back to default prompt."
    function global:prompt { Get-CustomPrompt }
}
