param(
  [string]$UserDataDir = 'C:\Users\humil\AppData\Local\Google\Chrome\User Data',
  [string]$ProfileDirectory = 'Default',
  [string]$StartUrl = 'https://www.naver.com/',
  [int]$AttachTimeoutSec = 25
)

$ErrorActionPreference = 'Stop'

# idempotency lock (avoid duplicate bootstrap collisions)
$lockDir = 'C:\openclaw\locks'
$lockPath = Join-Path $lockDir 'relay_bootstrap.lock'
New-Item -ItemType Directory -Force -Path $lockDir | Out-Null

if (Test-Path $lockPath) {
  $ageSec = [int]((Get-Date) - (Get-Item $lockPath).LastWriteTime).TotalSeconds
  if ($ageSec -lt 90) {
    Write-Output "relay_bootstrap_skip_locked ageSec=$ageSec"
    exit 0
  }
}
Set-Content -Path $lockPath -Value (Get-Date).ToString('o') -Encoding utf8

try {
  New-Item -ItemType Directory -Force -Path $UserDataDir | Out-Null

  # Check whether target profile chrome is already running
  $targetRunning = $false
  try {
    $procs = Get-CimInstance Win32_Process -Filter "name='chrome.exe'"
    foreach ($p in $procs) {
      $cmd = [string]$p.CommandLine
      if ($cmd -match [regex]::Escape($UserDataDir) -or ($UserDataDir -eq 'C:\Users\humil\AppData\Local\Google\Chrome\User Data' -and $cmd -notmatch '--user-data-dir=')) {
        $targetRunning = $true
        break
      }
    }
  } catch {}

  if (-not $targetRunning) {
    $args = @("--user-data-dir=$UserDataDir", "--profile-directory=$ProfileDirectory", "--new-window", $StartUrl)
    Start-Process chrome -ArgumentList $args | Out-Null
    Start-Sleep -Seconds 2
    Write-Output 'chrome_started_for_relay_bootstrap'
  } else {
    Write-Output 'chrome_already_running_target_profile'
  }

  # Single attach attempt path (reuse existing trained script; do not duplicate)
  & C:\openclaw\run.ps1 -Action relay_attach_train.ahk -TimeoutSec $AttachTimeoutSec | Out-Null

  Write-Output 'relay_bootstrap_done'
  exit 0
}
finally {
  Remove-Item -Path $lockPath -Force -ErrorAction SilentlyContinue
}
