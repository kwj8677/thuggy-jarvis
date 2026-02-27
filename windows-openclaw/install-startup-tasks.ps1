$ErrorActionPreference = 'Stop'

# Reliable startup chain:
# 1) warm up WSL Ubuntu
# 2) start OpenClaw gateway in WSL
# 3) run watchdog every 3 minutes

$taskWarm = 'OpenClawWSLWarmup'
$taskGate = 'OpenClawGatewayStart'
$taskWatch = 'OpenClawWatchdog'

schtasks.exe /Create /TN $taskWarm /SC ONLOGON /DELAY 0000:30 /TR "wsl -d Ubuntu --exec bash -lc \"echo warmup_ok >/tmp/openclaw/warmup.log\"" /F | Out-Null
schtasks.exe /Create /TN $taskGate /SC ONLOGON /DELAY 0001:00 /TR "wsl -d Ubuntu --exec bash -lc \"mkdir -p /tmp/openclaw; nohup openclaw gateway >/tmp/openclaw/boot-gateway.log 2>&1 &\"" /F | Out-Null
schtasks.exe /Create /TN $taskWatch /SC MINUTE /MO 3 /TR "pwsh.exe -WindowStyle Hidden -NoProfile -NonInteractive -ExecutionPolicy Bypass -File C:\temp\openclaw-ops\oc-watchdog.ps1" /F | Out-Null

Write-Output "TASKS_INSTALLED_OK: $taskWarm, $taskGate, $taskWatch"
