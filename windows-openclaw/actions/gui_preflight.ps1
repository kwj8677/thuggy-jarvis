param(
  [string]$CdpUrl = 'http://127.0.0.1:9222/json/version',
  [int]$CdpTimeoutSec = 3
)

$ErrorActionPreference = 'Stop'

function Test-Cdp {
  param([string]$Url,[int]$TimeoutSec)
  try {
    $res = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec $TimeoutSec
    if ($res.StatusCode -eq 200) {
      $obj = $res.Content | ConvertFrom-Json
      return [pscustomobject]@{
        ok = $true
        browser = $obj.Browser
        ws = $obj.webSocketDebuggerUrl
      }
    }
  } catch {}
  return [pscustomobject]@{ ok = $false; browser = $null; ws = $null }
}

function Get-PolicyValue {
  param([string]$HivePath,[string]$Name)
  try {
    $v = Get-ItemProperty -Path $HivePath -Name $Name -ErrorAction Stop
    return $v.$Name
  } catch {
    return $null
  }
}

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-gui-preflight.json")

$activeConsole = $null
try {
  $activeConsole = (quser 2>$null | Select-String ' console ' | Select-Object -First 1).Line
} catch {}

$chromeVisible = Get-Process chrome -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  Select-Object -First 1 Id, MainWindowTitle, MainWindowHandle

$policyHKLM = Get-PolicyValue -HivePath 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Name 'RemoteDebuggingAllowed'
$policyHKCU = Get-PolicyValue -HivePath 'HKCU:\SOFTWARE\Policies\Google\Chrome' -Name 'RemoteDebuggingAllowed'
$extHKLM = Get-PolicyValue -HivePath 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Name 'ExtensionSettings'
$extHKCU = Get-PolicyValue -HivePath 'HKCU:\SOFTWARE\Policies\Google\Chrome' -Name 'ExtensionSettings'

$cdp = Test-Cdp -Url $CdpUrl -TimeoutSec $CdpTimeoutSec

$checks = [ordered]@{
  interactiveSession = [bool]$activeConsole
  chromeVisibleWindow = [bool]$chromeVisible
  remoteDebuggingPolicy = (($policyHKLM -eq 1) -or ($policyHKCU -eq 1))
  cdpReachable = [bool]$cdp.ok
  extensionSettingsPresent = [bool]($extHKLM -or $extHKCU)
}

$failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })
$ok = ($failed.Count -eq 0)

$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  checks = $checks
  failedChecks = $failed
  diagnostics = [pscustomobject]@{
    activeConsole = $activeConsole
    chromeVisibleWindow = $chromeVisible
    remoteDebuggingAllowedHKLM = $policyHKLM
    remoteDebuggingAllowedHKCU = $policyHKCU
    cdp = $cdp
  }
}

$result | ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("PREFLIGHT_REPORT=" + $outPath)
Write-Output ("PREFLIGHT_OK=" + $ok)

if (-not $ok) { exit 21 }
exit 0
