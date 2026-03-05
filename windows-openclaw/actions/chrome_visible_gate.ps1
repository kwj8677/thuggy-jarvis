param(
  [int]$Retries = 3,
  [int]$WaitMs = 1500
)

$ErrorActionPreference = 'Stop'

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-chrome-visible-gate.json")

function Get-BrowserProc {
  Get-CimInstance Win32_Process -Filter "name='chrome.exe'" |
    Where-Object { -not ([string]$_.CommandLine -match '--type=') } |
    Select-Object -First 1 ProcessId,CommandLine
}

$attempts = @()
$ok = $false
for($i=1; $i -le $Retries; $i++) {
  schtasks /Run /TN OpenClaw_ChromeInteractive | Out-Null
  Start-Sleep -Milliseconds $WaitMs

  $browser = Get-BrowserProc
  $visible = Get-Process chrome -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Select-Object -First 1 Id,MainWindowHandle,MainWindowTitle

  $hit = [bool]$visible
  $attempts += [pscustomobject]@{
    attempt = $i
    browserPid = if($browser){$browser.ProcessId}else{$null}
    hasVisibleWindow = $hit
    visible = $visible
  }

  if($hit) { $ok = $true; break }

  # recovery: kill only browser root proc (no --type)
  if($browser){
    try { Stop-Process -Id $browser.ProcessId -Force -ErrorAction SilentlyContinue } catch {}
  }
  Start-Sleep -Milliseconds 600
}

$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  checks = [pscustomobject]@{
    retries = $Retries
  }
  attempts = $attempts
}

$result | ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("CHROME_VISIBLE_GATE_REPORT=" + $outPath)
Write-Output ("CHROME_VISIBLE_GATE_OK=" + $ok)
if(-not $ok){ exit 101 }
exit 0
