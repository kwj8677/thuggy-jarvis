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

$uiaRc = Run-Action 'relay_permission_grant_uia.ps1' 60
$wcRc = -1
$wcTried = $false

# Fallback to windows-control when UIA fails
if($uiaRc -ne 0){
  $wcTried = $true
  $py = '\\wsl.localhost\Ubuntu\home\humil\.agents\skills\windows-control\scripts\click_text.py'
  if(Test-Path $py){
    # Try Korean/English allow labels in current active window first
    py -3 $py '허용' | Out-Null
    if($LASTEXITCODE -ne 0){ py -3 $py 'Allow' | Out-Null }
    if($LASTEXITCODE -ne 0){ py -3 $py '항상 허용' | Out-Null }
    $wcRc = $LASTEXITCODE
  } else {
    $wcRc = 92
  }
}

# Verify by relay gate (tabs or attached)
$gateRc = Run-Action 'relay_tabs_gate.ps1' 45
$ok = ($gateRc -eq 0)

$result = [pscustomobject]@{
  ok = $ok
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
