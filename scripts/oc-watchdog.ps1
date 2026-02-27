$ErrorActionPreference = 'Continue'

$logDir = 'C:\temp\openclaw-ops'
$logFile = Join-Path $logDir 'oc_watchdog.log'
$stateFile = Join-Path $logDir 'oc_watchdog_state.json'
$cooldownSec = 600

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log([string]$msg) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ssK'
  "$ts`t$msg" | Out-File -FilePath $logFile -Append -Encoding utf8
}

function Get-State {
  if (Test-Path $stateFile) {
    try { return Get-Content $stateFile -Raw | ConvertFrom-Json } catch { }
  }
  return [pscustomobject]@{ lastRestartEpoch = 0 }
}

function Save-State($obj) {
  $obj | ConvertTo-Json | Out-File -FilePath $stateFile -Encoding utf8
}

# Health check via WSL safe probe script (authoritative)
$probeCmd = 'wsl bash -lc "/home/humil/.openclaw/workspace/scripts/openclaw-safe.sh probe >/dev/null 2>&1"'
cmd.exe /c $probeCmd | Out-Null
$ok = ($LASTEXITCODE -eq 0)

if ($ok) {
  Write-Log 'health=ok'
  exit 0
}

$state = Get-State
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$elapsed = $now - [int64]$state.lastRestartEpoch

if ($elapsed -lt $cooldownSec) {
  Write-Log "health=fail action=skip_cooldown elapsed=${elapsed}s"
  exit 1
}

Write-Log 'health=fail action=restart start'
cmd.exe /c 'wsl bash -lc "timeout 25s openclaw gateway restart >/tmp/openclaw/watchdog-restart.log 2>&1"' | Out-Null
$rc = $LASTEXITCODE

if ($rc -eq 0) {
  $state.lastRestartEpoch = $now
  Save-State $state
  Write-Log 'action=restart result=ok'

  # Optional lightweight Gemini summary (best effort)
  try {
    $tail = (Get-Content $logFile -Tail 20) -join "`n"
    $prompt = "OpenClaw watchdog 최근 로그를 2줄로 요약: `n$tail"
    & 'C:\Users\humil\AppData\Roaming\npm\gemini.ps1' -p $prompt --output-format text 2>$null | Out-File -FilePath (Join-Path $logDir 'oc_watchdog_gemini.log') -Encoding utf8
  } catch {}

  exit 0
}

Write-Log "action=restart result=fail rc=$rc"
exit 2
