param(
  [int]$MinVisibleWindows = 1
)

$ErrorActionPreference = 'Stop'

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-session-gate.json")

$activeConsole = $null
try { $activeConsole = (quser 2>$null | Select-String ' console ' | Select-Object -First 1).Line } catch {}

$visible = @()
try {
  $visible = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Select-Object -First 20 ProcessName,Id,MainWindowHandle,MainWindowTitle
} catch {}

$chromeVisible = @()
try {
  $chromeVisible = Get-Process chrome -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Select-Object -First 10 Id,MainWindowHandle,MainWindowTitle
} catch {}

$ok = [bool]$activeConsole -and ($visible.Count -ge $MinVisibleWindows)

$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  checks = [pscustomobject]@{
    interactiveConsole = [bool]$activeConsole
    visibleWindowCount = $visible.Count
    chromeVisibleWindowCount = $chromeVisible.Count
  }
  diagnostics = [pscustomobject]@{
    activeConsole = $activeConsole
    visibleWindows = $visible
    chromeVisible = $chromeVisible
  }
}

$result | ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("SESSION_GATE_REPORT=" + $outPath)
Write-Output ("SESSION_GATE_OK=" + $ok)

if (-not $ok) { exit 51 }
exit 0
