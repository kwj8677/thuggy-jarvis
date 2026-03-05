param(
  [int]$Runs = 5,
  [int]$PollSec = 90
)

$ErrorActionPreference = 'Stop'
$task = 'OpenClaw_Chrome_UIA_Interactive'

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-chrome-uia-deep-training.json")

$results = @()

for($i=1; $i -le $Runs; $i++) {
  # wait until task not running (avoid trigger miss)
  for($w=0; $w -lt 30; $w++) {
    $q = schtasks /Query /TN $task /V /FO LIST
    $running = ($q -match 'Running|실행 중')
    if(-not $running) { break }
    Start-Sleep -Seconds 1
  }

  $before = Get-ChildItem C:\openclaw\logs\*chrome-uia-pipeline.json -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  $beforePath = if($before){$before.FullName}else{''}

  schtasks /Run /TN $task | Out-Null
  $start = Get-Date

  $latest = $null
  for($p=0; $p -lt $PollSec; $p++) {
    Start-Sleep -Seconds 1
    $cand = Get-ChildItem C:\openclaw\logs\*chrome-uia-pipeline.json -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if($cand -and $cand.FullName -ne $beforePath -and $cand.LastWriteTime -ge $start) {
      $latest = $cand
      break
    }
  }

  if(-not $latest) {
    $results += [pscustomobject]@{
      run = $i
      ok = $false
      reason = 'trigger_miss_or_timeout'
      report = ''
    }
    continue
  }

  $ok = $false
  try {
    $j = Get-Content -Raw -Path $latest.FullName | ConvertFrom-Json
    $ok = [bool]$j.ok
  } catch {
    $ok = $false
  }

  $results += [pscustomobject]@{
    run = $i
    ok = $ok
    reason = if($ok){'ok'}else{'execution_fail'}
    report = $latest.FullName
  }
}

$success = @($results | Where-Object { $_.ok }).Count
$summary = [pscustomobject]@{
  runs = $Runs
  success = $success
  failure = ($Runs - $success)
  successRate = if($Runs -gt 0){ [Math]::Round($success / $Runs, 3) } else { 0 }
}

$final = [pscustomobject]@{
  runId = $runId
  timestamp = (Get-Date).ToString('o')
  summary = $summary
  results = $results
}

$final | ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("CHROME_UIA_DEEP_TRAINING_REPORT=" + $outPath)
Write-Output ("CHROME_UIA_DEEP_TRAINING_SUCCESS_RATE=" + $summary.successRate)
if($summary.success -lt $Runs){ exit 141 }
exit 0
