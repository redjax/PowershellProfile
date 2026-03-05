<#
    .SYNOPSIS
    Shell completions for Monolith profile.

    .DESCRIPTION
    Registers argument completers for various CLI tools:
    - Azure CLI (az)
    - Azure Developer CLI (azd)
    - Winget (Windows package manager)
    - Syst (Go application manager)
    - IntelliShell (cached completions)
    
    Note: 
    - Starship completions are loaded automatically by starship init in prompt.ps1
    - Git completions (posh-git) are loaded in background via OnIdle in Monolith.ps1
#>

#####################
# Shell Completions #
#####################

## Batch Get-Command check for completion tools (1 PATH scan instead of 4)
$_completionTools = @{}
Get-Command -Name az, azd, syst, 'intelli-shell.exe' -ErrorAction SilentlyContinue | ForEach-Object {
    $_completionTools[$_.Name] = $_
}

## Azure CLI completions
if ($_completionTools.ContainsKey('az')) {
    # Use cached completion file if it exists (much faster)
    $azCompletionFile = "$env:USERPROFILE\.azure\az.completion.ps1"
    if (Test-Path $azCompletionFile) {
        . $azCompletionFile
    }
}

## Azure Developer CLI completions
if ($_completionTools.ContainsKey('azd')) {
    # Use cached completion file if it exists (much faster)
    $azdCompletionFile = "$env:USERPROFILE\.azd\azd.completion.ps1"
    
    # Generate cache if it doesn't exist or is older than azd executable
    $azdExe = $_completionTools['azd'].Source
    if (-not (Test-Path $azdCompletionFile) -or 
        (Get-Item $azdCompletionFile).LastWriteTime -lt (Get-Item $azdExe).LastWriteTime) {
        
        $cacheDir = Split-Path $azdCompletionFile -Parent
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        
        azd completion powershell | Out-File -FilePath $azdCompletionFile -Encoding utf8
    }
    
    # Source the cached completion script
    . $azdCompletionFile
}

## Winget completions
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

## Syst completions
if ($_completionTools.ContainsKey('syst')) {
    # Use cached completion file if it exists (much faster)
    $userModulesPath = [Environment]::GetFolderPath('MyDocuments')
    $systCompletionFile = Join-Path -Path $userModulesPath -ChildPath "PowerShell\Completions\syst-completions.ps1"
    
    # Generate cache if it doesn't exist or is older than syst executable
    if (-not (Test-Path $systCompletionFile)) {
        $systExe = $_completionTools['syst'].Source
        if (-not (Test-Path $systCompletionFile) -or 
            (Get-Item $systCompletionFile).LastWriteTime -lt (Get-Item $systExe).LastWriteTime) {
            
            $cacheDir = Split-Path $systCompletionFile -Parent
            if (-not (Test-Path $cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
            }
            
            syst completion powershell | Out-File -FilePath $systCompletionFile -Encoding utf8
        }
    }
    
    # Source the cached completion script if it exists
    if (Test-Path $systCompletionFile) {
        . $systCompletionFile
    }
}

## IntelliShell
if ($_completionTools.ContainsKey('intelli-shell.exe')) {
    ## Use cached completion file if it exists (much faster)
    $userModulesPath = [Environment]::GetFolderPath('MyDocuments')
    $intelliCompletionFile = Join-Path -Path $userModulesPath -ChildPath "PowerShell\Completions\intelli-shell-completions.ps1"
    
    ## Set IntelliShell environment variables
    $env:INTELLI_HOME = "C:\Users\jkenyon\AppData\Roaming\IntelliShell\Intelli-Shell\data"
    
    ## Generate cache if it doesn't exist or is older than intelli-shell executable
    $intelliExe = $_completionTools['intelli-shell.exe'].Source
    if (-not (Test-Path $intelliCompletionFile) -or 
        (Get-Item $intelliCompletionFile).LastWriteTime -lt (Get-Item $intelliExe).LastWriteTime) {
        
        $cacheDir = Split-Path $intelliCompletionFile -Parent
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        
        try {
            intelli-shell.exe init powershell | Out-File -FilePath $intelliCompletionFile -Encoding utf8
        }
        catch {
            Write-Warning "Failed to generate IntelliShell completions: $($_.Exception.Message)"
        }
    }
    
    # Source the cached completion script if it exists
    if (Test-Path $intelliCompletionFile) {
        try {
            . $intelliCompletionFile
        }
        catch {
            Write-Warning "Failed to load IntelliShell completions: $($_.Exception.Message)"
            # Remove corrupt cache file
            Remove-Item -Path $intelliCompletionFile -Force -ErrorAction SilentlyContinue
        }
    }
}
