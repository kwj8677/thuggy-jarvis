$ErrorActionPreference = 'Stop'
$task = 'OpenClaw_Chrome_UIA_Interactive'
$user = $env:USERNAME
$cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\openclaw\run.ps1 -Action chrome_uia_pipeline.ps1 -TimeoutSec 90'
$st = (Get-Date).AddMinutes(1).ToString('HH:mm')

schtasks /Delete /TN $task /F 2>$null | Out-Null
schtasks /Create /TN $task /TR $cmd /SC ONCE /ST $st /RU $user /IT /F | Out-Null
schtasks /Run /TN $task | Out-Null
Write-Output 'CHROME_UIA_INTERACTIVE_TASK_STARTED'
