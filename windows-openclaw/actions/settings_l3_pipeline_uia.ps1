$ErrorActionPreference = 'Stop'
$runId=(Get-Date).ToString('yyyyMMdd-HHmmss')
$out="C:\openclaw\logs\$runId-settings-l3-pipeline-uia.json"
$steps=@()
function Step($n,$ok,$d){$script:steps += [pscustomobject]@{name=$n;ok=$ok;detail=$d;ts=(Get-Date).ToString('o')}}

& C:\openclaw\run.ps1 -Action session_gate.ps1 -TimeoutSec 20 | Out-Null
$rc1=$LASTEXITCODE; Step 'session_gate' ($rc1 -eq 0) "exitCode=$rc1"
if($rc1 -ne 0){ [pscustomobject]@{ok=$false;runId=$runId;reason='session_gate_failed';steps=$steps}|ConvertTo-Json -Depth 8|Out-File $out -Encoding utf8; exit 311 }

& C:\openclaw\run.ps1 -Action settings_l3_train_uia.ps1 -TimeoutSec 50 | Out-Null
$rc2=$LASTEXITCODE; Step 'settings_l3_train_uia' ($rc2 -eq 0) "exitCode=$rc2"

$ok = ($rc1 -eq 0 -and $rc2 -eq 0)
[pscustomobject]@{ok=$ok;runId=$runId;steps=$steps}|ConvertTo-Json -Depth 8|Out-File $out -Encoding utf8
Write-Output ("SETTINGS_L3_PIPELINE_UIA_REPORT="+$out)
Write-Output ("SETTINGS_L3_PIPELINE_UIA_OK="+$ok)
if(-not $ok){ exit 312 }
exit 0
