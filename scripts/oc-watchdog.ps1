$ErrorActionPreference = 'Continue'

$logDir = 'C:\temp\openclaw-ops'
$logFile = Join-Path $logDir 'oc_watchdog.log'
$stateFile = Join-Path $logDir 'oc_watchdog_state.json'
$reportJson = Join-Path $logDir 'oc_watchdog_last_incident.json'
$reportTxt = Join-Path $logDir 'oc_watchdog_last_incident.txt'
$cooldownSec = 600
$aiTimeoutSec = 20

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Write-Log([string]$msg) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ssK'
  "$ts`t$msg" | Out-File -FilePath $logFile -Append -Encoding utf8
}

function Get-State {
  if (Test-Path $stateFile) {
    try { return Get-Content $stateFile -Raw | ConvertFrom-Json } catch { }
  }
  return [pscustomobject]@{
    lastRestartEpoch = 0
    incidentActive = $false
    incidentStartedEpoch = 0
    failCount = 0
  }
}

function Save-State($obj) {
  $obj | ConvertTo-Json | Out-File -FilePath $stateFile -Encoding utf8
}

function Get-WslOpenclawTail {
  try {
    $cmd = 'wsl bash -lc "tail -n 240 /tmp/openclaw/openclaw-$(date +%F).log 2>/dev/null"'
    $out = cmd.exe /c $cmd | Out-String
    return $out
  } catch {
    return ''
  }
}

function Classify-Failure([string]$ctx) {
  $lc = ($ctx | Out-String).ToLowerInvariant()
  if ($lc -match 'token mismatch|token missing|unauthorized') {
    return [pscustomobject]@{ kind='auth_mismatch'; evidence='token/unauthorized pattern' }
  }
  if ($lc -match 'llm request timed out|all models failed|rpc: failed - timeout|connect: failed - timeout') {
    return [pscustomobject]@{ kind='timeout_or_model'; evidence='timeout/failover pattern' }
  }
  if ($lc -match 'drain timeout reached|received sigterm|received sigusr1|restarting anyway') {
    return [pscustomobject]@{ kind='restart_during_active_tasks'; evidence='restart/drain pattern' }
  }
  if ($lc -match 'port 18789 is already in use|already running|lock timeout') {
    return [pscustomobject]@{ kind='port_or_lock_conflict'; evidence='port/lock conflict pattern' }
  }
  return [pscustomobject]@{ kind='unknown'; evidence='no strong signature found' }
}

function Get-AiDecision([string]$context) {
  # Safe default is restart. AI can only veto restart with explicit "skip".
  $default = [pscustomobject]@{ action = 'restart'; reason = 'default_fallback' }

  if (-not $env:GEMINI_API_KEY -or [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
    return $default
  }

  try {
    $prompt = @"
너는 OpenClaw watchdog 운영 보조자다.
아래 로그 컨텍스트를 보고 action을 JSON 한 줄로만 답해라.
허용 action: restart 또는 skip
기준:
- 인증/토큰 mismatch, 일시 timeout, probe fail: restart
- 너무 잦은 재시작 반복, 의도적 점검/중단 징후: skip
출력 형식 정확히:
{"action":"restart|skip","reason":"짧은이유"}

컨텍스트:
$context
"@

    Set-Location 'C:\Users\humil'

    $job = Start-Job -ScriptBlock {
      param($p)
      & 'C:\Users\humil\AppData\Roaming\npm\gemini.ps1' -p $p --output-format text
    } -ArgumentList $prompt

    $done = Wait-Job -Job $job -Timeout $aiTimeoutSec
    if (-not $done) {
      Stop-Job -Job $job | Out-Null
      Remove-Job -Job $job | Out-Null
      return $default
    }

    $out = (Receive-Job -Job $job | Out-String).Trim()
    Remove-Job -Job $job | Out-Null

    $jsonLine = ($out -split "`r?`n" | Where-Object { $_ -match '\{.*\}' } | Select-Object -First 1)
    if (-not $jsonLine) { return $default }

    $obj = $jsonLine | ConvertFrom-Json
    if ($obj.action -in @('restart', 'skip')) {
      return [pscustomobject]@{ action = $obj.action; reason = ($obj.reason | Out-String).Trim() }
    }

    return $default
  }
  catch {
    return $default
  }
}

function Save-IncidentReport($report) {
  try {
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportJson -Encoding utf8

    $txt = @()
    $txt += "incident_at=$($report.incident_at)"
    $txt += "classification=$($report.classification)"
    $txt += "evidence=$($report.evidence)"
    $txt += "ai_action=$($report.ai_action) ai_reason=$($report.ai_reason)"
    $txt += "recovery_action=$($report.recovery_action) rc=$($report.restart_rc)"
    $txt += "recovery_probe=$($report.recovery_probe)"
    $txt += "recovered_at=$($report.recovered_at)"
    $txt += "duration_sec=$($report.duration_sec)"
    $txt += "fail_count=$($report.fail_count)"
    $txt -join "`n" | Out-File -FilePath $reportTxt -Encoding utf8
  } catch {}
}

# Health check via WSL safe probe script (authoritative)
$probeCmd = 'wsl bash -lc "/home/humil/.openclaw/workspace/scripts/openclaw-safe.sh probe >/dev/null 2>&1"'
cmd.exe /c $probeCmd | Out-Null
$ok = ($LASTEXITCODE -eq 0)

$state = Get-State
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

if ($ok) {
  # close stale incident state if any
  if ($state.incidentActive) {
    $state.incidentActive = $false
    $state.incidentStartedEpoch = 0
    Save-State $state
  }
  Write-Log 'health=ok'
  exit 0
}

# failure path
if (-not $state.incidentActive) {
  $state.incidentActive = $true
  $state.incidentStartedEpoch = $now
  $state.failCount = 1
} else {
  $state.failCount = [int]$state.failCount + 1
}
Save-State $state

$elapsed = $now - [int64]$state.lastRestartEpoch
if ($elapsed -lt $cooldownSec) {
  Write-Log "health=fail action=skip_cooldown elapsed=${elapsed}s fail_count=$($state.failCount)"
  exit 1
}

$ctxWsl = Get-WslOpenclawTail
$class = Classify-Failure $ctxWsl
$decision = Get-AiDecision (($ctxWsl + "`n" + (Get-Content $logFile -Tail 40 | Out-String)))
Write-Log "ai_action=$($decision.action) ai_reason=$($decision.reason) class=$($class.kind)"

if ($decision.action -eq 'skip') {
  Write-Log "health=fail action=skip_by_ai class=$($class.kind)"
  exit 3
}

Write-Log "health=fail action=restart start class=$($class.kind)"
$restartCmd = 'wsl bash -lc "timeout 25s openclaw gateway restart >/tmp/openclaw/watchdog-restart.log 2>/tmp/openclaw/watchdog-restart.err"'
cmd.exe /c $restartCmd | Out-Null
$rc = $LASTEXITCODE
if ($rc -ne 0) {
  try {
    $errTail = (cmd.exe /c 'wsl bash -lc "tail -n 30 /tmp/openclaw/watchdog-restart.err 2>/dev/null"' | Out-String).Trim()
    if ($errTail) { Write-Log ("restart_stderr=" + $errTail.Replace("`n",' | ')) }
  } catch {}
}

# post-restart probe check
Start-Sleep -Seconds 2
cmd.exe /c $probeCmd | Out-Null
$probeOk = ($LASTEXITCODE -eq 0)

if ($rc -eq 0 -and $probeOk) {
  $state.lastRestartEpoch = $now
  $state.incidentActive = $false
  $duration = $now - [int64]$state.incidentStartedEpoch
  $failCount = [int]$state.failCount
  $state.incidentStartedEpoch = 0
  $state.failCount = 0
  Save-State $state

  Write-Log 'action=restart result=ok recovery_probe=ok'

  $report = [pscustomobject]@{
    incident_at = (Get-Date -Date ([DateTimeOffset]::FromUnixTimeSeconds($now).DateTime) -Format 'yyyy-MM-dd HH:mm:ssK')
    classification = $class.kind
    evidence = $class.evidence
    ai_action = $decision.action
    ai_reason = $decision.reason
    recovery_action = 'gateway_restart'
    restart_rc = $rc
    recovery_probe = 'ok'
    recovered_at = (Get-Date -Format 'yyyy-MM-dd HH:mm:ssK')
    duration_sec = $duration
    fail_count = $failCount
  }
  Save-IncidentReport $report

  # Optional post-recovery Gemini summary (best effort)
  try {
    $tail = (Get-Content $logFile -Tail 20) -join "`n"
    $prompt2 = "OpenClaw watchdog 최근 로그를 2줄로 요약: `n$tail"
    if ($env:GEMINI_API_KEY -and -not [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
      Set-Location 'C:\Users\humil'
      $geminiOut = & 'C:\Users\humil\AppData\Roaming\npm\gemini.ps1' -p $prompt2 --output-format text 2>$null
      if ($LASTEXITCODE -eq 0 -and $geminiOut) {
        $geminiOut | Out-File -FilePath (Join-Path $logDir 'oc_watchdog_gemini.log') -Encoding utf8
        Write-Log 'gemini=ok'
      }
      else {
        Write-Log "gemini=skip rc=$LASTEXITCODE"
      }
    }
    else {
      Write-Log 'gemini=skip reason=no_api_key'
    }
  }
  catch {
    Write-Log ("gemini=fail err=" + $_.Exception.Message)
  }

  exit 0
}

Write-Log "action=restart result=fail rc=$rc recovery_probe=$($probeOk ? 'ok' : 'fail') class=$($class.kind)"
exit 2
