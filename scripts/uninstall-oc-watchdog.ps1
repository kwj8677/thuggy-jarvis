$ErrorActionPreference = 'Continue'
$taskName = 'OpenClawWatchdog'
schtasks /Delete /TN $taskName /F | Out-Null
Write-Output "TASK_REMOVED:$taskName"
