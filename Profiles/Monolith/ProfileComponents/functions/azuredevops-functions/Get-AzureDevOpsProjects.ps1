## Function to get all projects
function Get-AzureDevOpsProjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "Azure DevOps organization name")]
        [string]$Organization = $env:AZURE_DEVOPS_ORG,
        
        [Parameter(Mandatory = $false, HelpMessage = "Personal Access Token")]
        [string]$PersonalAccessToken = $env:AZURE_DEVOPS_PAT,
        
        [Parameter(Mandatory = $false, HelpMessage = "Path to file containing PAT")]
        [string]$PersonalAccessTokenFile = $env:AZURE_DEVOPS_PAT_FILE
    )
    
    ## Validate Organization
    if ([string]::IsNullOrWhiteSpace($Organization)) {
        Write-Error "Organization is required. Provide -Organization parameter or set AZURE_DEVOPS_ORG environment variable."
        return
    }
    
    ## Determine PAT to use (prefer explicit token over file)
    $Pat = $null
    if (-not [string]::IsNullOrWhiteSpace($PersonalAccessToken)) {
        $Pat = $PersonalAccessToken
    }
    elseif (-not [string]::IsNullOrWhiteSpace($PersonalAccessTokenFile)) {
        if (Test-Path $PersonalAccessTokenFile) {
            try {
                $Pat = (Get-Content $PersonalAccessTokenFile -Raw).Trim()
                if ([string]::IsNullOrWhiteSpace($Pat)) {
                    Write-Error "PAT file exists but is empty: $PersonalAccessTokenFile"
                    return
                }
            }
            catch {
                Write-Error "Failed to read PAT from file '$PersonalAccessTokenFile': $_"
                return
            }
        }
        else {
            Write-Error "PAT file not found: $PersonalAccessTokenFile"
            return
        }
    }
    else {
        Write-Error "PAT is required. Provide -PersonalAccessToken parameter, -PersonalAccessTokenFile parameter, set AZURE_DEVOPS_PAT environment variable, or set AZURE_DEVOPS_PAT_FILE environment variable."
        return
    }
    
    Write-Host "Fetching projects from Azure DevOps organization: $Organization" -ForegroundColor Green
    
    $projectsUri = "https://dev.azure.com/$Organization/_apis/projects?api-version=7.0"
    $projectsResponse = Invoke-AzureDevOpsApi -Uri $projectsUri -Pat $Pat
    
    if ($projectsResponse -and $projectsResponse.value) {
        Write-Host "Found $($projectsResponse.value.Count) projects" -ForegroundColor Yellow
        return $projectsResponse.value
    }
    else {
        Write-Warning "No projects found or failed to retrieve projects"
        return @()
    }
}