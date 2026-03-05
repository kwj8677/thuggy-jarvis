$ErrorActionPreference = 'Stop'

Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$chrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path $chrome)) {
  $chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
}
if (-not (Test-Path $chrome)) {
  throw "Chrome executable not found"
}

Start-Process -FilePath $chrome -ArgumentList @(
  '--remote-debugging-address=0.0.0.0',
  '--remote-debugging-port=9222',
  '--user-data-dir=C:\Users\humil\AppData\Local\Google\Chrome\User Data',
  '--profile-directory=Default',
  '--new-window',
  'https://www.naver.com'
)

Start-Sleep -Seconds 2

$net = netstat -ano | Select-String ':9222'
if (-not $net) {
  Write-Output 'CDP_PORT_NOT_LISTENING'
  exit 2
}

try {
  $v = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:9222/json/version' -TimeoutSec 3
  Write-Output 'CDP_OK'
  Write-Output $v.Content
} catch {
  Write-Output 'CDP_HTTP_FAIL'
  Write-Output $_.Exception.Message
  exit 3
}
