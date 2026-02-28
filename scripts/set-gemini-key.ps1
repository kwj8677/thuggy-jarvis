$ErrorActionPreference = 'Stop'
param([Parameter(Mandatory=$true)][string]$ApiKey)
[Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $ApiKey, 'User')
$env:GEMINI_API_KEY = $ApiKey
Set-Location 'C:\Users\humil'
gemini --version
