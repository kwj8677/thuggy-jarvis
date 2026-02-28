$ErrorActionPreference = 'Stop'
$k = 'AIzaSyAEjATJ1jXmUdfTyqBNJBp1WPXj2bnbu9M'
[Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $k, 'User')
$env:GEMINI_API_KEY = $k
Set-Location 'C:\Users\humil'
gemini --version
