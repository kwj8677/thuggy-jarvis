param(
  [Parameter(Mandatory=$true)][string]$Action,
  [string]$ActionArgs = "",
  [int]$TimeoutSec = 0,
  [int]$MaxRetries = -1,
  [switch]$Approve
)

$ErrorActionPreference = 'Stop'
$base = 'C:\openclaw'
$actions = Join-Path $base 'actions'
$logs = Join-Path $base 'logs'
$policyPath = Join-Path $base 'action-policy.json'

New-Item -ItemType Directory -Force -Path $actions, $logs | Out-Null

$actionPath = Join-Path $actions $Action
if (-not (Test-Path $actionPath)) {
  Write-Error "Action not found: $actionPath"
  exit 2
}

function Get-Policy {
  param([string]$Name)
  $def = [pscustomobject]@{ timeoutSec=60; maxRetries=1; retryBackoffSec=2; risk='low'; requiresApproval=$false }
  if (-not (Test-Path $policyPath)) { return $def }
  try {
    $j = Get-Content $policyPath -Raw | ConvertFrom-Json
    $d = $j.defaults
    if ($d) {
      $def.timeoutSec = [int]($d.timeoutSec)
      $def.maxRetries = [int]($d.maxRetries)
      $def.retryBackoffSec = [int]($d.retryBackoffSec)
      $def.risk = [string]($d.risk)
      $def.requiresApproval = [bool]($d.requiresApproval)
    }
    $a = $j.actions.$Name
    if ($a) {
      if ($a.PSObject.Properties.Name -contains 'timeoutSec') { $def.timeoutSec = [int]$a.timeoutSec }
      if ($a.PSObject.Properties.Name -contains 'maxRetries') { $def.maxRetries = [int]$a.maxRetries }
      if ($a.PSObject.Properties.Name -contains 'retryBackoffSec') { $def.retryBackoffSec = [int]$a.retryBackoffSec }
      if ($a.PSObject.Properties.Name -contains 'risk') { $def.risk = [string]$a.risk }
      if ($a.PSObject.Properties.Name -contains 'requiresApproval') { $def.requiresApproval = [bool]$a.requiresApproval }
    }
  } catch {}
  return $def
}

$policy = Get-Policy -Name $Action
if ($TimeoutSec -le 0) { $TimeoutSec = $policy.timeoutSec }
if ($MaxRetries -lt 0) { $MaxRetries = $policy.maxRetries }

if ($policy.requiresApproval -and -not $Approve) {
  Write-Error "Approval required for action '$Action' (risk=$($policy.risk)). Re-run with -Approve."
  exit 10
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$name = [IO.Path]::GetFileNameWithoutExtension($Action)
$runId = "$ts-$name"
$log = Join-Path $logs ("$runId.log")
$errLog = Join-Path $logs ("$runId.err.log")
$metaLog = Join-Path $logs ("$runId.meta.json")
$ext = [IO.Path]::GetExtension($actionPath).ToLowerInvariant()

function Write-Meta($attempt,$rc,$result,[string]$reason='') {
  [pscustomobject]@{
    action=$Action
    actionPath=$actionPath
    runId=$runId
    attempt=$attempt
    timeoutSec=$TimeoutSec
    maxRetries=$MaxRetries
    risk=$policy.risk
    requiresApproval=$policy.requiresApproval
    result=$result
    exitCode=$rc
    reason=$reason
    timestamp=(Get-Date).ToString('o')
  } | ConvertTo-Json -Depth 4 | Out-File -FilePath $metaLog -Encoding utf8
}

function Run-PS1 {
  param([string]$Path,[string]$Args,[int]$WaitSec,[string]$StdOut,[string]$StdErr)
  $argLine = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$Path`" $Args"
  $p = Start-Process -FilePath "pwsh.exe" -ArgumentList $argLine -PassThru -WindowStyle Hidden -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr
  if (-not $p.WaitForExit($WaitSec * 1000)) {
    try { $p.Kill() } catch {}
    return 124
  }
  return $p.ExitCode
}

function Ensure-AHK {
  $ahkExe = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
  if (Test-Path $ahkExe) { return $ahkExe }
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install autohotkey -y | Out-File -FilePath $log -Append -Encoding utf8
  }
  if (Test-Path $ahkExe) { return $ahkExe }
  return $null
}

function Run-AHK {
  param([string]$Path,[int]$WaitSec,[string]$StdOut)
  $ahkExe = Ensure-AHK
  if (-not $ahkExe) {
    "AutoHotkey not found." | Out-File -FilePath $StdOut -Encoding utf8
    return 3
  }
  $p = Start-Process -FilePath $ahkExe -ArgumentList "`"$Path`"" -PassThru -WindowStyle Hidden
  if (-not $p.WaitForExit($WaitSec * 1000)) {
    try { $p.Kill() } catch {}
    "TIMEOUT after ${WaitSec}s" | Out-File -FilePath $StdOut -Encoding utf8
    return 124
  }
  "AHK_EXIT=$($p.ExitCode)" | Out-File -FilePath $StdOut -Encoding utf8
  return $p.ExitCode
}

$attempt = 0
$rc = 1
while ($attempt -le $MaxRetries) {
  $attempt++
  if ($ext -eq '.ps1') {
    $rc = Run-PS1 -Path $actionPath -Args $ActionArgs -WaitSec $TimeoutSec -StdOut $log -StdErr $errLog
  } elseif ($ext -eq '.ahk') {
    $rc = Run-AHK -Path $actionPath -WaitSec $TimeoutSec -StdOut $log
  } else {
    Write-Error "Unsupported action extension: $ext"
    Write-Meta -attempt $attempt -rc 4 -result 'failed' -reason 'unsupported_extension'
    exit 4
  }

  if ($rc -eq 0) {
    Write-Meta -attempt $attempt -rc $rc -result 'ok'
    exit 0
  }

  $reason = if ($rc -eq 124) { 'timeout' } else { 'nonzero_exit' }
  if ($attempt -le $MaxRetries) {
    "RETRY $attempt/$MaxRetries after ${($policy.retryBackoffSec)}s (rc=$rc)" | Out-File -FilePath $log -Append -Encoding utf8
    Start-Sleep -Seconds ([int]$policy.retryBackoffSec)
  } else {
    Write-Meta -attempt $attempt -rc $rc -result 'failed' -reason $reason
    exit $rc
  }
}
