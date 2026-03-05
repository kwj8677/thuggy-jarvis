$chrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path $chrome)) { $chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe' }
if (-not (Test-Path $chrome)) { throw 'chrome not found' }

$arg = '"' + $chrome + '" --new-window https://www.google.com'
$ws = New-Object -ComObject WScript.Shell
$null = $ws.Run($arg, 1, $false)
Write-Output 'LAUNCH_SENT'
