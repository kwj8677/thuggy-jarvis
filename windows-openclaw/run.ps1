param(
  [Parameter(Mandatory=$true)][string]$Action,
  [string]$ActionArgs = "",
  [int]$TimeoutSec = 60
)

$ErrorActionPreference = 'Stop'
$base = 'C:\openclaw'
$actions = Join-Path $base 'actions'
$logs = Join-Path $base 'logs'
New-Item -ItemType Directory -Force -Path $actions, $logs | Out-Null

$actionPath = Join-Path $actions $Action
if (-not (Test-Path $actionPath)) {
  Write-Error "Action not found: $actionPath"
  exit 2
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$name = [IO.Path]::GetFileNameWithoutExtension($Action)
$log = Join-Path $logs ("$ts-$name.log")
$ext = [IO.Path]::GetExtension($actionPath).ToLowerInvariant()

if ($ext -eq '.ps1') {
  $argLine = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$actionPath`" $ActionArgs"
  $errLog = [IO.Path]::ChangeExtension($log, '.err.log')
  $p = Start-Process -FilePath "pwsh.exe" -ArgumentList $argLine -PassThru -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $errLog
  if (-not $p.WaitForExit($TimeoutSec * 1000)) {
    try { $p.Kill() } catch {}
    "TIMEOUT after ${TimeoutSec}s" | Out-File -FilePath $log -Append -Encoding utf8
    exit 124
  }
  exit $p.ExitCode
}
elseif ($ext -eq '.ahk') {
  $ahkExe = 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
  if (-not (Test-Path $ahkExe)) {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
      choco install autohotkey -y | Out-File -FilePath $log -Append -Encoding utf8
    }
  }

  if (-not (Test-Path $ahkExe)) {
    "AutoHotkey not found. install failed or path changed." | Out-File -FilePath $log -Encoding utf8
    exit 3
  }

  $p = Start-Process -FilePath $ahkExe -ArgumentList "`"$actionPath`"" -PassThru -WindowStyle Hidden
  if (-not $p.WaitForExit($TimeoutSec * 1000)) {
    try { $p.Kill() } catch {}
    "TIMEOUT after ${TimeoutSec}s" | Out-File -FilePath $log -Encoding utf8
    exit 124
  }

  "AHK_EXIT=$($p.ExitCode)" | Out-File -FilePath $log -Encoding utf8
  exit $p.ExitCode
}
else {
  Write-Error "Unsupported action extension: $ext"
  exit 4
}
