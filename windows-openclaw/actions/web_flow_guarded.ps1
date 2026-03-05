param([int]$MaxAttempts=2)
$ErrorActionPreference='Stop'
$logDir='C:\openclaw\logs'; New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$runId=(Get-Date).ToString('yyyyMMdd-HHmmss')
$out=Join-Path $logDir "$runId-web-flow-guarded.json"

function LogFallback([string]$skill,[string]$reason){
  & 'C:\openclaw\actions\fallback_log.ps1' -Skill $skill -Reason $reason | Out-Null
}

$steps=@()

# 1) Launch chrome path
& 'C:\openclaw\run.ps1' -Action 'chrome_l1_launch_uia.ps1' -TimeoutSec 40 | Out-Null
$rc=$LASTEXITCODE; $steps += [pscustomobject]@{step='chrome_l1_launch_uia';exit=$rc}
if($rc -ne 0){
  LogFallback 'windows-uia-advanced' 'chrome_l1_launch_failed'
  & 'C:\openclaw\run.ps1' -Action 'chrome_uia_pipeline.ps1' -TimeoutSec 120 | Out-Null
  $rc2=$LASTEXITCODE; $steps += [pscustomobject]@{step='chrome_uia_pipeline';exit=$rc2}
}

# 2) Relay attach chain
& 'C:\openclaw\run.ps1' -Action 'relay_icon_target_train_uia.ps1' -TimeoutSec 45 | Out-Null
$icon=$LASTEXITCODE; $steps += [pscustomobject]@{step='relay_icon_target_train_uia';exit=$icon}

$gate=61
for($i=1;$i -le $MaxAttempts;$i++){
  & 'C:\openclaw\run.ps1' -Action 'relay_permission_auto.ps1' -TimeoutSec 90 | Out-Null
  $perm=$LASTEXITCODE; $steps += [pscustomobject]@{step="relay_permission_auto#$i";exit=$perm}
  & 'C:\openclaw\run.ps1' -Action 'relay_tabs_gate.ps1' -TimeoutSec 45 | Out-Null
  $gate=$LASTEXITCODE; $steps += [pscustomobject]@{step="relay_tabs_gate#$i";exit=$gate}
  if($gate -eq 0){ break }
  LogFallback 'browser-relay' 'no_attached_tab_or_permission_blocked'
}

if($gate -ne 0){
  LogFallback 'midscene-computer-automation' 'relay_path_unstable'
  LogFallback 'ahk' 'final_fallback_placeholder'
}

$ok = ($gate -eq 0)
$result=[pscustomobject]@{ok=$ok;runId=$runId;steps=$steps}
$result|ConvertTo-Json -Depth 8 | Out-File -FilePath $out -Encoding utf8
Write-Output ("WEB_FLOW_GUARDED_REPORT="+$out)
Write-Output ("WEB_FLOW_GUARDED_OK="+$ok)
if(-not $ok){ exit 191 }
exit 0
