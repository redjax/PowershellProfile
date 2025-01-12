# ## Dynamically loads all function scripts from the Functions directory.

# ## Get the directory of the current module
# $moduleBasePath = Split-Path -Parent $MyInvocation.MyCommand.Definition
# $functionsPath = Join-Path -Path $moduleBasePath -ChildPath "Functions"
# $aliasesPath = Join-Path -Path $moduleBasePath -ChildPath "Aliases.ps1"

# ## Check if the Functions directory exists
# if (-Not (Test-Path -Path $functionsPath)) {
#     Write-Error "Functions directory not found: $functionsPath"
#     return
# }

# ## Function to check if a function is uncommented
# function Test-FunctionIsUncommented {
#     param (
#         [string]$functionScript
#     )

#     # Read the file content
#     $content = Get-Content -Path $functionScript -Raw

#     # Use a regex to find function definitions (handle different styles of comments)
#     $functions = Select-String -Pattern 'function\s+(\w+)' -InputObject $content

#     return $functions
# }

# ## Dot-source each script in the Functions directory and export valid functions
# Get-ChildItem -Path $functionsPath -Filter "*.ps1" | ForEach-Object {
#     Write-Host "Loading function script: $($_.FullName)"

#     # Dot-source the script
#     . $_.FullName

#     # Identify and export uncommented functions
#     $validFunctions = Test-FunctionIsUncommented -functionScript $_.FullName

#     foreach ($function in $validFunctions) {
#         $functionName = $function.Matches.Groups[1].Value

#         # Export only if the function is defined (and not commented)
#         if (Get-Command -Name $functionName -ErrorAction SilentlyContinue) {
#             Export-ModuleMember -Function $functionName
#             Write-Host "Exporting function: $functionName"
#         }
#     }
# }

# ## Check if the aliases.ps1 file exists
# if (-Not (Test-Path -Path $aliasesPath -PathType Leaf)) {
#     Write-Error "Aliases file not found: $aliasesPath"
#     return
# }

# ## Dot-source the aliases.ps1 file
# . $aliasesPath

# Export-ModuleMember -Function * -Alias *
