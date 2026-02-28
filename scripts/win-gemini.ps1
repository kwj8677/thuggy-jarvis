param(
  [Parameter(Mandatory=$true)][string]$Prompt
)
$ErrorActionPreference = 'Stop'
if (-not $env:GEMINI_API_KEY -or [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
  throw 'GEMINI_API_KEY is not set in environment.'
}
Set-Location 'C:\Users\humil'
gemini $Prompt
