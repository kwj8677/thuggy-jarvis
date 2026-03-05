$ErrorActionPreference = 'Stop'

$chrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path $chrome)) { $chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe' }
if (-not (Test-Path $chrome)) { throw 'chrome not found' }

$user = "$env:USERDOMAIN\$env:USERNAME"
$task = 'OpenClaw_ChromeInteractive'
$time = (Get-Date).AddMinutes(1).ToString('HH:mm')
$tr = '"' + $chrome + '" --new-window https://www.google.com'

schtasks /Create /TN $task /TR $tr /SC ONCE /ST $time /RU $user /IT /F | Out-Null
schtasks /Run /TN $task | Out-Null
Write-Output "TASK_RUN $task as $user at $time"
