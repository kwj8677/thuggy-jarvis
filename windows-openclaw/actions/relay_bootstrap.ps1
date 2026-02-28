$ErrorActionPreference = 'Stop'

$profileDir = 'C:\openclaw\chrome-profile'
$startUrl = 'https://www.naver.com/'
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

# Launch dedicated Chrome profile (isolates toolbar state for relay training)
Start-Process chrome -ArgumentList "--user-data-dir=$profileDir --new-window $startUrl"
Start-Sleep -Seconds 2

# Run attach training click sequence
& C:\openclaw\run.ps1 -Action relay_attach_train.ahk -TimeoutSec 25 | Out-Null

Write-Output 'relay_bootstrap_done'
