$ErrorActionPreference = 'Stop'

$task = 'OpenClaw_WinGuiL1_UIA_Interactive'
$user = $env:USERNAME
$cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\openclaw\run.ps1 -Action win_gui_l1_pipeline_uia.ps1 -TimeoutSec 90'
$st = (Get-Date).AddMinutes(1).ToString('HH:mm')

schtasks /Delete /TN $task /F 2>$null | Out-Null
schtasks /Create /TN $task /TR $cmd /SC ONCE /ST $st /RU $user /IT /F | Out-Null
schtasks /Run /TN $task | Out-Null
Start-Sleep -Seconds 3

Write-Output 'WIN_GUI_L1_UIA_INTERACTIVE_TASK_STARTED'
exit 0
