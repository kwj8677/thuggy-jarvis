param(
  [string[]]$BaseUrls = @('http://127.0.0.1:18792','http://127.0.0.1:18791'),
  [int]$MinTabs = 1,
  [int]$Retries = 4,
  [int]$SleepMs = 1200
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-relay-tabs-gate.json")

$lastStatus = $null
$lastTabs = $null
$tabCount = 0
$selectedBase = ''
$attachedWindows = 0

for($i=0; $i -lt $Retries; $i++) {
  foreach($base in $BaseUrls){
    try {
      $s = Invoke-WebRequest -UseBasicParsing -Uri ($base + '/status') -TimeoutSec 3
      if ($s.StatusCode -eq 200) { $lastStatus = $s.Content | ConvertFrom-Json; $selectedBase = $base }
    } catch {}

    try {
      $t = Invoke-WebRequest -UseBasicParsing -Uri ($base + '/tabs') -TimeoutSec 3
      if ($t.StatusCode -eq 200) {
        $lastTabs = $t.Content | ConvertFrom-Json
        if ($lastTabs.tabs) { $tabCount = @($lastTabs.tabs).Count } else { $tabCount = 0 }
        $selectedBase = $base
      }
    } catch {}

    if ($tabCount -ge $MinTabs) { break }
  }

  # UIA attached-state probe (fallback evidence)
  try {
    $attachedWindows = 0
    $procs = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }
    foreach($p in $procs){
      $root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
      if(-not $root){ continue }
      $btnCond = New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::Button
      )
      $btns = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
      for($k=0; $k -lt $btns.Count; $k++){
        $n = [string]$btns.Item($k).Current.Name
        if($n -match 'OpenClaw Browser Relay' -and $n -match 'attached') { $attachedWindows++; break }
      }
    }
  } catch {}

  if (($tabCount -ge $MinTabs) -or ($attachedWindows -ge 1)) { break }
  Start-Sleep -Milliseconds $SleepMs
}

$okByTabs = ($tabCount -ge $MinTabs)
$okByAttached = ($attachedWindows -ge 1)
$ok = ($okByTabs -or $okByAttached)

$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  checks = [pscustomobject]@{
    minTabs = $MinTabs
    tabCount = $tabCount
    retries = $Retries
    selectedBase = $selectedBase
    attachedWindows = $attachedWindows
    okByTabs = $okByTabs
    okByAttached = $okByAttached
  }
  diagnostics = [pscustomobject]@{
    status = $lastStatus
    tabs = $lastTabs
  }
}

$result | ConvertTo-Json -Depth 12 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("RELAY_TABS_GATE_REPORT=" + $outPath)
Write-Output ("RELAY_TABS_GATE_OK=" + $ok)

if (-not $ok) { exit 61 }
exit 0
