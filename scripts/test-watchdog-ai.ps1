$ErrorActionPreference = 'Stop'
if (-not $env:GEMINI_API_KEY -or [string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
  throw 'GEMINI_API_KEY is required in environment.'
}

$aiTimeoutSec = 20
$context = @"
maintenance window planned by operator
multiple restarts in short interval
please avoid restart loop for now
"@

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
  Write-Output 'AI_TIMEOUT'
  exit 2
}

$out = (Receive-Job -Job $job | Out-String).Trim()
Remove-Job -Job $job | Out-Null
Write-Output $out
