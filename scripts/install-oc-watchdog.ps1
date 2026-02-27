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
$tr = "pwsh.exe -WindowStyle Hidden -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`""
# Run as current user (WSL context compatibility) but hidden window to avoid popup
schtasks /Create /TN $taskName /SC MINUTE /MO 3 /TR $tr /RU "$env:USERDOMAIN\$env:USERNAME" /RL HIGHEST /F | Out-Null

Write-Output "TASK_INSTALLED_GHOST_USER:$taskName"
