$ErrorActionPreference = 'Continue'

$logDir = 'C:\temp\openclaw-ops'
$logFile = Join-Path $logDir 'oc_watchdog.log'
$stateFile = Join-Path $logDir 'oc_watchdog_state.json'
$cooldownSec = 600
$aiTimeoutSec = 12

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
      Stop-Job -Job $job -Force | Out-Null
      Remove-Job -Job $job -Force | Out-Null
      return $default
    }

    $out = (Receive-Job -Job $job | Out-String).Trim()
    Remove-Job -Job $job -Force | Out-Null

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

$context = (Get-Content $logFile -Tail 30 | Out-String)
$decision = Get-AiDecision $context
Write-Log "ai_action=$($decision.action) ai_reason=$($decision.reason)"

if ($decision.action -eq 'skip') {
  Write-Log 'health=fail action=skip_by_ai'
  exit 3
}

Write-Log 'health=fail action=restart start'
cmd.exe /c 'wsl bash -lc "timeout 25s openclaw gateway restart >/tmp/openclaw/watchdog-restart.log 2>&1"' | Out-Null
$rc = $LASTEXITCODE

if ($rc -eq 0) {
  $state.lastRestartEpoch = $now
  Save-State $state
  Write-Log 'action=restart result=ok'

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

Write-Log "action=restart result=fail rc=$rc"
exit 2
