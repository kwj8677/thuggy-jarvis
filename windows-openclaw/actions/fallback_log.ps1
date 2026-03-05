param(
  [Parameter(Mandatory=$true)][string]$Skill,
  [Parameter(Mandatory=$true)][string]$Reason
)
$logDir='C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$path=Join-Path $logDir 'fallback-router.log'
$line="$(Get-Date -Format o) Fallback to $Skill because $Reason"
Add-Content -Path $path -Value $line -Encoding utf8
Write-Output $line
