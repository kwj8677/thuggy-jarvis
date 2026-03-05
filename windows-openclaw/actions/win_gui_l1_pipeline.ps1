$ErrorActionPreference = 'Stop'

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-win-gui-l1-pipeline.json")

$steps = @()
function Add-Step($name,$ok,$detail){
  $script:steps += [pscustomobject]@{name=$name; ok=$ok; detail=$detail; ts=(Get-Date).ToString('o')}
}

# Gate 1: interactive session
& C:\openclaw\run.ps1 -Action session_gate.ps1 -TimeoutSec 20 | Out-Null
$rc1 = $LASTEXITCODE
Add-Step 'session_gate' ($rc1 -eq 0) ("exitCode=" + $rc1)
if ($rc1 -ne 0) {
  $result = [pscustomobject]@{ ok=$false; runId=$runId; reason='session_gate_failed'; steps=$steps }
  $result | ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
  Write-Output ("WIN_GUI_L1_PIPELINE_REPORT=" + $outPath)
  exit 81
}

# Action: Notepad GUI training
& C:\openclaw\run.ps1 -Action notepad_l1_train.ahk -TimeoutSec 30 | Out-Null
$rc2 = $LASTEXITCODE
Add-Step 'notepad_l1_train' ($rc2 -eq 0) ("exitCode=" + $rc2)
if ($rc2 -ne 0) {
  $result = [pscustomobject]@{ ok=$false; runId=$runId; reason='train_failed'; steps=$steps }
  $result | ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
  Write-Output ("WIN_GUI_L1_PIPELINE_REPORT=" + $outPath)
  exit 82
}

# Verify
& C:\openclaw\run.ps1 -Action notepad_l1_verify.ps1 -TimeoutSec 20 | Out-Null
$rc3 = $LASTEXITCODE
Add-Step 'notepad_l1_verify' ($rc3 -eq 0) ("exitCode=" + $rc3)

$ok = ($rc1 -eq 0 -and $rc2 -eq 0 -and $rc3 -eq 0)
$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  steps = $steps
}
$result | ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
Write-Output ("WIN_GUI_L1_PIPELINE_REPORT=" + $outPath)
Write-Output ("WIN_GUI_L1_PIPELINE_OK=" + $ok)
if (-not $ok) { exit 83 }
exit 0
