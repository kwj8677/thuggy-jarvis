param(
  [Parameter(Mandatory=$true)][string]$Prompt,
  [string]$OutputFormat = "text"
)

$ErrorActionPreference = 'Stop'

if (-not $env:GEMINI_API_KEY -or [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
  throw "GEMINI_API_KEY is not set in Windows environment."
}

Set-Location 'C:\Users\humil'

gemini -p $Prompt --output-format $OutputFormat
