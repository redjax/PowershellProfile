<#
    .SYNOPSIS
    Shell completions for Monolith profile.

    .DESCRIPTION
    Registers argument completers for various CLI tools:
    - Azure CLI (az)
    - Azure Developer CLI (azd)
    - Winget (Windows package manager)
    - Syst (Go application manager)
    
    Note: Starship completions are loaded automatically by starship init in prompt.ps1
#>

#####################
# Shell Completions #
#####################

## Azure CLI completions
if ($global:CommandCache['az']) {
    # Use cached completion file if it exists (much faster)
    $azCompletionFile = "$env:USERPROFILE\.azure\az.completion.ps1"
    if (Test-Path $azCompletionFile) {
        . $azCompletionFile
    }
}

## Azure Developer CLI completions
if ($global:CommandCache['azd']) {
    # Use cached completion file if it exists (much faster)
    $azdCompletionFile = "$env:USERPROFILE\.azd\azd.completion.ps1"
    
    # Generate cache if it doesn't exist or is older than azd executable
    $azdExe = (Get-Command azd).Source
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
if ($global:CommandCache['syst']) {
    # Use cached completion file if it exists (much faster)
    $userModulesPath = [Environment]::GetFolderPath('MyDocuments')
    $systCompletionFile = Join-Path -Path $userModulesPath -ChildPath "PowerShell\Completions\syst-completions.ps1"
    
    # Generate cache if it doesn't exist or is older than syst executable
    if (-not (Test-Path $systCompletionFile)) {
        $systExe = (Get-Command syst).Source
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




