param(
  [int]$Runs = 3,
  [int]$PollSec = 120
)

$ErrorActionPreference = 'Stop'
$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-relay-uia-deep-training.json")

$results=@()
for($i=1; $i -le $Runs; $i++){
  $before = Get-ChildItem C:\openclaw\logs\*relay-uia-pipeline.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  $beforePath = if($before){$before.FullName}else{''}

  & C:\openclaw\run.ps1 -Action relay_uia_pipeline.ps1 -TimeoutSec 120 | Out-Null

  $latest=$null
  $start=Get-Date
  for($w=0; $w -lt $PollSec; $w++){
    Start-Sleep -Seconds 1
    $cand = Get-ChildItem C:\openclaw\logs\*relay-uia-pipeline.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if($cand -and $cand.FullName -ne $beforePath -and $cand.LastWriteTime -ge $start){ $latest=$cand; break }
  }

  if(-not $latest){
    $results += [pscustomobject]@{run=$i;ok=$false;reason='trigger_miss_or_timeout';report=''}
    continue
  }

  $ok=$false
  try { $j=Get-Content -Raw -Path $latest.FullName | ConvertFrom-Json; $ok=[bool]$j.ok } catch { $ok=$false }
  $results += [pscustomobject]@{run=$i;ok=$ok;reason=(if($ok){'ok'}else{'execution_fail'});report=$latest.FullName}
}

$success=@($results|Where-Object{$_.ok}).Count
$summary=[pscustomobject]@{runs=$Runs;success=$success;failure=($Runs-$success);successRate=if($Runs -gt 0){[Math]::Round($success/$Runs,3)}else{0}}
$out=[pscustomobject]@{runId=$runId;timestamp=(Get-Date).ToString('o');summary=$summary;results=$results}
$out|ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
Write-Output ("RELAY_UIA_DEEP_TRAINING_REPORT="+$outPath)
Write-Output ("RELAY_UIA_DEEP_TRAINING_SUCCESS_RATE="+$summary.successRate)
if($summary.success -lt $Runs){ exit 171 }
exit 0
