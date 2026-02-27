$ErrorActionPreference = 'Stop'
$taskName = 'OpenClawWatchdog'
$src = '\\wsl.localhost\Ubuntu\home\humil\.openclaw\workspace\scripts\oc-watchdog.ps1'
$dstDir = 'C:\temp\openclaw-ops'
$scriptPath = Join-Path $dstDir 'oc-watchdog.ps1'

New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
if (-not (Test-Path $src)) {
  throw "watchdog source not found: $src"
}
Copy-Item -Force $src $scriptPath

# Create/replace scheduled task every 3 minutes (ghost/background)
schtasks /Delete /TN $taskName /F 2>$null | Out-Null
$tr = "pwsh.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`""
# Run as SYSTEM to avoid interactive console popups on user desktop
schtasks /Create /TN $taskName /SC MINUTE /MO 3 /TR $tr /RU SYSTEM /RL HIGHEST /F | Out-Null

Write-Output "TASK_INSTALLED_GHOST:$taskName"
