# Show all custom functions and aliases from profile
function Show-ProfileFunctions {
    [CmdletBinding()]
    param()

    # Find the ProfileComponents directory
    $profileDir = Split-Path $PROFILE -Parent
    $componentsDir = Join-Path $profileDir "ProfileComponents"
    
    if (-not (Test-Path $componentsDir)) {
        Write-Warning "ProfileComponents directory not found at: $componentsDir"
        return
    }

    # Collections to store discovered items
    $allFunctions = @()
    $allAliases = @()

    Write-Host "`n=== Scanning ProfileComponents for Functions and Aliases ===" -ForegroundColor Cyan
    Write-Host "Directory: $componentsDir`n" -ForegroundColor Gray

    # Recursively get all .ps1 files in ProfileComponents
    $psFiles = Get-ChildItem -Path $componentsDir -Filter "*.ps1" -Recurse -File

    Write-Host "Found $($psFiles.Count) PowerShell files to scan..." -ForegroundColor Gray

    foreach ($file in $psFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction Stop
            
            # Parse function definitions (both 'function' and 'Function')
            $functionPattern = '(?m)^(?:function|Function)\s+([a-zA-Z][\w-]*)'
            $functions = [regex]::Matches($content, $functionPattern) | ForEach-Object {
                [PSCustomObject]@{
                    Name = $_.Groups[1].Value
                    File = $file.FullName.Replace($componentsDir, "ProfileComponents")
                }
            }
            
            if ($functions) {
                $allFunctions += $functions
            }

            # Parse alias definitions (Set-Alias with various formats)
            $aliasPattern = '(?m)^Set-Alias\s+(?:-Name\s+)?[''"]?([a-zA-Z][\w-]*)[''"]?\s+(?:-Value\s+)?[''"]?([^\s''"]+)'
            $aliases = [regex]::Matches($content, $aliasPattern) | ForEach-Object {
                [PSCustomObject]@{
                    Name   = $_.Groups[1].Value
                    Target = $_.Groups[2].Value
                    File   = $file.FullName.Replace($componentsDir, "ProfileComponents")
                }
            }
            
            if ($aliases) {
                $allAliases += $aliases
            }
        }
        catch {
            Write-Warning "Error reading file $($file.Name): $_"
        }
    }

    # Display Functions
    Write-Host "`n=== Custom Functions ===" -ForegroundColor Cyan
    
    if ($allFunctions.Count -eq 0) {
        Write-Host "  No functions found." -ForegroundColor Gray
    }
    else {
        $allFunctions | Sort-Object Name -Unique | ForEach-Object {
            Write-Host "  $($_.Name.PadRight(40))" -NoNewline -ForegroundColor Yellow
            Write-Host "  [$($_.File)]" -ForegroundColor DarkGray
        }
        Write-Host "`n  Total: $($allFunctions.Count) functions" -ForegroundColor Gray
    }

    # Display Aliases
    Write-Host "`n=== Custom Aliases ===" -ForegroundColor Cyan
    
    if ($allAliases.Count -eq 0) {
        Write-Host "  No aliases found." -ForegroundColor Gray
    }
    else {
        $allAliases | Sort-Object Name -Unique | ForEach-Object {
            Write-Host "  $($_.Name.PadRight(20))" -NoNewline -ForegroundColor Magenta
            Write-Host "→ $($_.Target.PadRight(25))" -NoNewline -ForegroundColor Cyan
            Write-Host "  [$($_.File)]" -ForegroundColor DarkGray
        }
        Write-Host "`n  Total: $($allAliases.Count) aliases" -ForegroundColor Gray
    }

    Write-Host ""
}

Set-Alias -Name "profile-help" -Value "Show-ProfileFunctions"
Set-Alias -Name "phelp" -Value "Show-ProfileFunctions"
