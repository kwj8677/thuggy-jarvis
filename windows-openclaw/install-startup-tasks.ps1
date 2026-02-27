$ErrorActionPreference = 'Stop'

$taskWarm  = 'OpenClawWSLWarmup'
$taskGate  = 'OpenClawGatewayStart'
$taskWatch = 'OpenClawWatchdog'

$watchdogDstDir = 'C:\temp\openclaw-ops'
$watchdogDst = Join-Path $watchdogDstDir 'oc-watchdog.ps1'
$watchdogSrc = '\\wsl.localhost\Ubuntu\home\humil\.openclaw\workspace\scripts\oc-watchdog.ps1'

New-Item -ItemType Directory -Force -Path $watchdogDstDir | Out-Null
if (Test-Path $watchdogSrc) { Copy-Item -Force $watchdogSrc $watchdogDst }

# Remove existing tasks (ignore errors)
cmd /c "schtasks.exe /Delete /TN $taskWarm /F" | Out-Null
cmd /c "schtasks.exe /Delete /TN $taskGate /F" | Out-Null
cmd /c "schtasks.exe /Delete /TN $taskWatch /F" | Out-Null

# Recreate tasks (popup-minimized, non-overlapping by schedule)
cmd /c "schtasks.exe /Create /TN $taskWarm /SC ONLOGON /DELAY 0000:30 /TR \"wsl -d Ubuntu --exec bash -lc \\\"echo warmup_ok\\\"\" /RL HIGHEST /F" | Out-Null
cmd /c "schtasks.exe /Create /TN $taskGate /SC ONLOGON /DELAY 0001:00 /TR \"wsl -d Ubuntu --exec bash -lc \\\"openclaw gateway\\\"\" /RL HIGHEST /F" | Out-Null
cmd /c "schtasks.exe /Create /TN $taskWatch /SC MINUTE /MO 3 /TR \"pwsh.exe -WindowStyle Hidden -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\\temp\\openclaw-ops\\oc-watchdog.ps1\" /RL HIGHEST /F" | Out-Null

Write-Output "TASKS_INSTALLED_POPUP_FREE: $taskWarm, $taskGate, $taskWatch"
