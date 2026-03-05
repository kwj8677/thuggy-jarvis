$ErrorActionPreference = 'Stop'
$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-relay-uia-pipeline.json")

$steps=@()
function Add-Step($name,$ok,$detail){ $script:steps += [pscustomobject]@{name=$name;ok=$ok;detail=$detail;ts=(Get-Date).ToString('o')} }

# Gate hardening: require session gate pass twice
& C:\openclaw\run.ps1 -Action session_gate.ps1 -TimeoutSec 20 | Out-Null
$g1=$LASTEXITCODE
Add-Step 'session_gate_1' ($g1 -eq 0) ("exitCode=$g1")
Start-Sleep -Milliseconds 700
& C:\openclaw\run.ps1 -Action session_gate.ps1 -TimeoutSec 20 | Out-Null
$g2=$LASTEXITCODE
Add-Step 'session_gate_2' ($g2 -eq 0) ("exitCode=$g2")
if($g1 -ne 0 -or $g2 -ne 0){
  $r=[pscustomobject]@{ok=$false;runId=$runId;reason='session_gate_unstable';steps=$steps}
  $r|ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
  Write-Output ("RELAY_UIA_PIPELINE_REPORT="+$outPath)
  exit 160
}

& C:\openclaw\run.ps1 -Action chrome_uia_pipeline.ps1 -TimeoutSec 90 | Out-Null
$rc1=$LASTEXITCODE
Add-Step 'chrome_uia_pipeline' ($rc1 -eq 0) ("exitCode=$rc1")
if($rc1 -ne 0){
  $r=[pscustomobject]@{ok=$false;runId=$runId;reason='chrome_uia_pipeline_failed';steps=$steps}
  $r|ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
  Write-Output ("RELAY_UIA_PIPELINE_REPORT="+$outPath)
  exit 161
}

& C:\openclaw\run.ps1 -Action relay_attach_uia.ps1 -TimeoutSec 25 | Out-Null
$rc2=$LASTEXITCODE
Add-Step 'relay_attach_uia' ($rc2 -eq 0) ("exitCode=$rc2")

& C:\openclaw\run.ps1 -Action relay_tabs_gate.ps1 -TimeoutSec 20 | Out-Null
$rc3=$LASTEXITCODE
Add-Step 'relay_tabs_gate' ($rc3 -eq 0) ("exitCode=$rc3")

$ok = ($rc1 -eq 0 -and $rc2 -eq 0 -and $rc3 -eq 0)
$r=[pscustomobject]@{ok=$ok;runId=$runId;steps=$steps}
$r|ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
Write-Output ("RELAY_UIA_PIPELINE_REPORT="+$outPath)
Write-Output ("RELAY_UIA_PIPELINE_OK="+$ok)
if(-not $ok){ exit 162 }
exit 0
