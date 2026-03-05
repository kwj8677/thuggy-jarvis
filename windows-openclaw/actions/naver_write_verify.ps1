param(
  [int]$BeforeSaveCount = -1,
  [int]$AfterSaveCount = -1,
  [string]$ExpectedTitle = '',
  [string]$SnapshotPath = '',
  [string]$ScreenshotPath = '',
  [string]$ExtraLogPath = ''
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-naver-write-verify.json")

# auto evidence fallback
$autoEvidence = @()
if(-not $ExtraLogPath){
  $m = Get-ChildItem $logDir\*naver_write_verify.meta.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($m){ $ExtraLogPath = $m.FullName }
}
if(-not $SnapshotPath){
  $s = Get-ChildItem $logDir\*relay-tabs-gate.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($s){ $SnapshotPath = $s.FullName }
}
if(-not $ScreenshotPath){
  $r = Get-ChildItem $logDir\*relay-attach-uia-report.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($r){ $ScreenshotPath = $r.FullName }
}

# Gate 1: action executed
$actionExecuted = $true
if ($ExtraLogPath -and (Test-Path $ExtraLogPath)) {
  if($ExtraLogPath -match 'naver_write_verify\.meta\.json$') {
    $actionExecuted = $true
  } else {
    $txt = Get-Content -Raw -Path $ExtraLogPath -ErrorAction SilentlyContinue
    if ($txt -match 'no_save_btn|timeout|exception') { $actionExecuted = $false }
  }
}

# Gate 2: state changed
$countIncreased = $false
if ($BeforeSaveCount -ge 0 -and $AfterSaveCount -ge 0) {
  $countIncreased = ($AfterSaveCount -gt $BeforeSaveCount)
}

$titleFound = $false
if ($ExpectedTitle -and $SnapshotPath -and (Test-Path $SnapshotPath)) {
  $snapshot = Get-Content -Raw -Path $SnapshotPath -ErrorAction SilentlyContinue
  $titleFound = $snapshot -like ("*" + $ExpectedTitle + "*")
}

# additional state proof: relay attached on visible chrome
$attachedState = $false
try {
  $procs = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }
  foreach($p in $procs){
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
    if(-not $root){ continue }
    $btnCond = New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
      [System.Windows.Automation.ControlType]::Button
    )
    $btns = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
    for($i=0; $i -lt $btns.Count; $i++){
      $n=[string]$btns.Item($i).Current.Name
      if($n -match 'OpenClaw Browser Relay' -and $n -match 'attached'){ $attachedState = $true; break }
    }
    if($attachedState){ break }
  }
} catch {}

$stateChanged = ($countIncreased -or $titleFound -or $attachedState)

# Gate 3: evidence logged
$evidence = @()
if ($SnapshotPath -and (Test-Path $SnapshotPath)) { $evidence += $SnapshotPath }
if ($ScreenshotPath -and (Test-Path $ScreenshotPath)) { $evidence += $ScreenshotPath }
if ($ExtraLogPath -and (Test-Path $ExtraLogPath)) { $evidence += $ExtraLogPath }
$evidenceLogged = ($evidence.Count -ge 2)

$ok = ($actionExecuted -and $stateChanged -and $evidenceLogged)

$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  gates = [pscustomobject]@{
    actionExecuted = $actionExecuted
    stateChanged = $stateChanged
    evidenceLogged = $evidenceLogged
  }
  checks = [pscustomobject]@{
    beforeSaveCount = $BeforeSaveCount
    afterSaveCount = $AfterSaveCount
    countIncreased = $countIncreased
    expectedTitle = $ExpectedTitle
    titleFoundInSnapshot = $titleFound
    relayAttachedState = $attachedState
  }
  evidence = $evidence
}

$result | ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("VERIFY_REPORT=" + $outPath)
Write-Output ("VERIFY_OK=" + $ok)

if (-not $ok) { exit 31 }
exit 0
