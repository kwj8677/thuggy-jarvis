$ErrorActionPreference = 'Stop'
$task = 'OpenClaw_ChromeInteractive'
$user = $env:USERNAME
$cmdPath = 'C:\openclaw\actions\launch_chrome_visible.cmd'

if (-not (Test-Path $cmdPath)) { throw "Missing: $cmdPath" }

# Recreate task cleanly
schtasks /Delete /TN $task /F 2>$null | Out-Null
schtasks /Create /TN $task /TR $cmdPath /SC ONLOGON /RU $user /IT /F | Out-Null

# Run now
schtasks /Run /TN $task | Out-Null
Start-Sleep -Seconds 2

# Verification
$q = schtasks /Query /TN $task /V /FO LIST
$chrome = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 5 Id,MainWindowTitle,MainWindowHandle

Write-Output 'TASK_OK'
$q | Select-String 'TaskName|Run As User|Status|Last Run Result|Task To Run'
Write-Output 'CHROME_WINDOWS'
$chrome | Format-Table -AutoSize
