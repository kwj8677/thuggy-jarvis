param(
  [Parameter(Mandatory=$true)][string]$Prompt
)
$ErrorActionPreference = 'Stop'
$env:GEMINI_API_KEY = 'AIzaSyAEjATJ1jXmUdfTyqBNJBp1WPXj2bnbu9M'
Set-Location 'C:\Users\humil'
gemini $Prompt
