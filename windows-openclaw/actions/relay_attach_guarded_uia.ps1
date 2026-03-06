param(
  [int]$MaxAttempts = 1,
  [int]$TotalTimeoutSec = 60,
  [int]$AttachTimeoutSec = 35,
  [int]$VerifyTimeoutSec = 20,
  [int]$CooldownSec = 900,
  [int]$FailWindowSec = 1800,
  [int]$FailThreshold = 3,
  [switch]$StrictFailFast = $true
)

$ErrorActionPreference = 'Stop'

$stateDir = 'C:\openclaw\state'
$logDir = 'C:\openclaw\logs'
$lockPath = Join-Path $stateDir 'relay-attach.lock'
$statePath = Join-Path $stateDir 'relay-attach-state.json'

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$runId = (Get-Date).ToString('yyyyMMdd-HHmmss')
$reportPath = Join-Path $logDir ("$runId-relay-attach-guarded.json")

function Load-State {
  if (!(Test-Path $statePath)) {
    return @{ failures=@(); open=$false; openedAt=0; lastSuccessAt=0; lastFailureAt=0 }
  }
  try {
    $raw = Get-Content -Path $statePath -Raw -Encoding UTF8
    return ($raw | ConvertFrom-Json -AsHashtable)
  } catch {
    return @{ failures=@(); open=$false; openedAt=0; lastSuccessAt=0; lastFailureAt=0 }
  }
}

function Save-State([hashtable]$s) {
  $s | ConvertTo-Json -Depth 10 | Out-File -FilePath $statePath -Encoding utf8
}

function Save-Report([bool]$ok, [string]$reason, [hashtable]$data) {
  $obj = [ordered]@{
    ok = $ok
    reason = $reason
    runId = $runId
    timestamp = (Get-Date).ToString('o')
    data = $data
  }
  $obj | ConvertTo-Json -Depth 15 | Out-File -FilePath $reportPath -Encoding utf8
  Write-Output ("RELAY_ATTACH_GUARDED_REPORT=" + $reportPath)
  Write-Output ("RELAY_ATTACH_GUARDED_OK=" + $ok)
}

# lock guard
if (Test-Path $lockPath) {
  try {
    $lockRaw = Get-Content -Path $lockPath -Raw -Encoding UTF8
    $lock = $lockRaw | ConvertFrom-Json
    $ts = [int64]$lock.ts
    $age = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $ts)
    if ($age -lt $TotalTimeoutSec) {
      Save-Report $false 'lock_active' @{ lockAgeSec=$age; lockPath=$lockPath }
      exit 71
    }
  } catch {}
}

@{ ts=[DateTimeOffset]::UtcNow.ToUnixTimeSeconds(); runId=$runId } |
  ConvertTo-Json | Out-File -FilePath $lockPath -Encoding utf8

$state = Load-State
$nowTs = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$state.failures = @($state.failures | Where-Object { ($_ -as [int64]) -ge ($nowTs - $FailWindowSec) })

if ($state.open -eq $true) {
  $openAge = [int]($nowTs - [int64]$state.openedAt)
  if ($openAge -lt $CooldownSec) {
    Save-Report $false 'circuit_open_cooldown' @{ openAgeSec=$openAge; cooldownSec=$CooldownSec; failuresInWindow=@($state.failures).Count }
    Remove-Item -Path $lockPath -Force -ErrorAction SilentlyContinue
    exit 72
  } else {
    $state.open = $false
    $state.openedAt = 0
  }
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$attempts = @()
$backoff = @(2,5,10)
$ok = $false
$finalReason = 'unknown'

$effectiveAttempts = if ($StrictFailFast) { 1 } else { $MaxAttempts }

for ($i=1; $i -le $effectiveAttempts; $i++) {
  if ($sw.Elapsed.TotalSeconds -ge $TotalTimeoutSec) {
    $finalReason = 'total_timeout'
    break
  }

  $attempt = [ordered]@{ idx=$i; attachRc=$null; verifyRc=$null; elapsedSec=[int]$sw.Elapsed.TotalSeconds }

  & 'C:\openclaw\run.ps1' -Action 'relay_attach_uia.ps1' -TimeoutSec $AttachTimeoutSec
  $attempt.attachRc = $LASTEXITCODE

  if ($attempt.attachRc -eq 0) {
    Start-Sleep -Milliseconds 800
    & 'C:\openclaw\run.ps1' -Action 'relay_tabs_gate.ps1' -TimeoutSec $VerifyTimeoutSec
    $attempt.verifyRc = $LASTEXITCODE

    if ($attempt.verifyRc -eq 0) {
      # hard proof gate: require visible chrome window + attachedWindows evidence in latest gate report
      $visibleChrome = @(Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }).Count
      $gateReportFile = Get-ChildItem -Path $logDir -Filter '*relay-tabs-gate.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
      $attachedWindows = 0
      if($gateReportFile){
        try {
          $gateJson = Get-Content -Path $gateReportFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
          $attachedWindows = [int]$gateJson.checks.attachedWindows
        } catch {}
      }
      $attempt.visibleChrome = $visibleChrome
      $attempt.attachedWindows = $attachedWindows

      if ($visibleChrome -ge 1 -and $attachedWindows -ge 1) {
        $ok = $true
        $finalReason = 'ok'
        $attempts += $attempt
        break
      } else {
        $finalReason = 'verify_weak_signal'
      }
    }
  }

  $attempts += $attempt

  if ($i -lt $effectiveAttempts) {
    $sleepSec = $backoff[[Math]::Min($i-1, $backoff.Count-1)]
    Start-Sleep -Seconds $sleepSec
  }
}

if ($ok) {
  $state.lastSuccessAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $state.failures = @()
  $state.open = $false
  $state.openedAt = 0
  Save-State $state
  Save-Report $true $finalReason @{ attempts=$attempts; elapsedSec=[int]$sw.Elapsed.TotalSeconds; statePath=$statePath }
  Remove-Item -Path $lockPath -Force -ErrorAction SilentlyContinue
  exit 0
}

# failure path
$state.lastFailureAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$state.failures += [int64]$state.lastFailureAt
$recentFails = @($state.failures | Where-Object { ($_ -as [int64]) -ge ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $FailWindowSec) }).Count
if ($recentFails -ge $FailThreshold) {
  $state.open = $true
  $state.openedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $finalReason = if ($finalReason -eq 'unknown') { 'failed_and_circuit_opened' } else { "$finalReason`_and_circuit_opened" }
}
Save-State $state
# Attach RCA hints from latest component reports if available
$latestAttach = Get-ChildItem -Path $logDir -Filter '*relay-attach-uia-report.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$latestGate = Get-ChildItem -Path $logDir -Filter '*relay-tabs-gate.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$rca = [ordered]@{
  latestAttachReport = if($latestAttach){$latestAttach.FullName}else{''}
  latestTabsGateReport = if($latestGate){$latestGate.FullName}else{''}
  recommendation = 'Check attach report reason -> compare with known patterns -> patch and rerun single-attempt test.'
}

Save-Report $false $finalReason @{ attempts=$attempts; elapsedSec=[int]$sw.Elapsed.TotalSeconds; recentFails=$recentFails; statePath=$statePath; rca=$rca }
Remove-Item -Path $lockPath -Force -ErrorAction SilentlyContinue
exit 73
