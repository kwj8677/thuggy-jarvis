$u = whoami
$task = 'OpenClaw_ChromeInteractive2'
$st = (Get-Date).AddMinutes(1).ToString('HH:mm')
$cmdPath = 'C:\openclaw\actions\launch_chrome_visible.cmd'
'start "" chrome --new-window https://www.google.com' | Out-File -FilePath $cmdPath -Encoding ascii -Force
$tr = $cmdPath

schtasks /Create /TN $task /TR $tr /SC ONCE /ST $st /RU $u /IT /F
schtasks /Run /TN $task
schtasks /Query /TN $task /V /FO LIST | Select-String 'Task To Run|Run As User|Last Run Result|Status'
