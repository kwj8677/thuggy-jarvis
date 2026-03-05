param(
  [string[]]$ExtensionIds = @('nglingapjinhecnfejdcpihlpneeadjp','pfhemcnpfilapbppdkfemikblgnnikdp')
)

$ErrorActionPreference = 'Stop'
$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-relay-force-site-access.json")

$chrome = Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'
if(-not (Test-Path $chrome)){ $chrome = Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe' }

$fastClick = '\\wsl.localhost\Ubuntu\home\humil\.openclaw\workspace\windows-openclaw\actions\relay_permission_click_default.py'

$steps = @()
$ok = $false

foreach($id in $ExtensionIds){
  if(Test-Path $chrome){
    Start-Process -FilePath $chrome -ArgumentList "--new-window chrome://extensions/?id=$id" | Out-Null
    Start-Sleep -Seconds 2
  }

  # fast generic button clicking burst (avoids long UIA scans)
  $rc = 99
  if(Test-Path $fastClick){
    py -3 $fastClick | Out-Null
    $rc = $LASTEXITCODE
  }
  $steps += [pscustomobject]@{extensionId=$id;fastClickExit=$rc}
  Start-Sleep -Milliseconds 500
}

# verify via existing chain
& 'C:\openclaw\run.ps1' -Action 'relay_icon_target_train_uia.ps1' -TimeoutSec 45 | Out-Null
$iconRc = $LASTEXITCODE
& 'C:\openclaw\run.ps1' -Action 'relay_tabs_gate.ps1' -TimeoutSec 45 | Out-Null
$gateRc = $LASTEXITCODE
$ok = ($gateRc -eq 0)

$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  checks = [pscustomobject]@{
    iconExit = $iconRc
    gateExit = $gateRc
  }
  attempts = $steps
}
$result | ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("RELAY_FORCE_SITE_ACCESS_REPORT=" + $outPath)
Write-Output ("RELAY_FORCE_SITE_ACCESS_OK=" + $ok)
if(-not $ok){ exit 185 }
exit 0
