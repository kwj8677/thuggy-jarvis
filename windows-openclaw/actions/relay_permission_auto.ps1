param(
  [int]$TimeoutSec = 60
)

$ErrorActionPreference = 'Stop'
$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-relay-permission-auto.json")

function Run-Action($name,$timeout){
  & 'C:\openclaw\run.ps1' -Action $name -TimeoutSec $timeout | Out-Null
  return $LASTEXITCODE
}

$uiaRc = Run-Action 'relay_permission_grant_uia.ps1' 12
$wcRc = -1
$wcTried = $false

# Stage 2: one short windows-control attempt only
if($uiaRc -ne 0){
  $wcTried = $true
  $py = '\\wsl.localhost\Ubuntu\home\humil\.agents\skills\windows-control\scripts\click_text.py'
  if(Test-Path $py){
    py -3 $py '허용' 'Chrome' | Out-Null
    $wcRc = $LASTEXITCODE
  } else {
    $wcRc = 92
  }
}

# Verify by relay gate (tabs or attached)
$gateRc = Run-Action 'relay_tabs_gate.ps1' 12
$ok = ($gateRc -eq 0)
$reason = 'ok'
if(-not $ok){
  if(($uiaRc -eq 183) -and (-not $wcTried -or $wcRc -ne 0)){
    $reason = 'permission_popup_not_visible'
  } else {
    $reason = 'permission_click_failed'
  }
}

$result = [pscustomobject]@{
  ok = $ok
  reason = $reason
  runId = $runId
  timestamp = $now.ToString('o')
  checks = [pscustomobject]@{
    uiaPermissionExit = $uiaRc
    windowsControlTried = $wcTried
    windowsControlExit = $wcRc
    relayGateExit = $gateRc
  }
}

$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("RELAY_PERMISSION_AUTO_REPORT=" + $outPath)
Write-Output ("RELAY_PERMISSION_AUTO_OK=" + $ok)
if(-not $ok){ exit 184 }
exit 0
