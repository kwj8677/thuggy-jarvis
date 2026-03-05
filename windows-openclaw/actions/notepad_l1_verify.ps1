$ErrorActionPreference = 'Stop'

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
$outPath = Join-Path $logDir ("$runId-notepad-l1-verify.json")
$target = 'C:\openclaw\logs\notepad-l1-output.txt'

$exists = $false
$content = ''
$hasMarker = $false
for($i=0; $i -lt 8; $i++) {
  $exists = Test-Path $target
  if ($exists) { break }
  Start-Sleep -Milliseconds 300
}
if ($exists) {
  try {
    $content = Get-Content -Raw -Path $target -ErrorAction Stop
    $hasMarker = ($content -match 'L1TRAINMARKER-')
  } catch {}
}

$ok = ($exists -and $hasMarker)
$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  checks = [pscustomobject]@{
    fileExists = $exists
    hasMarker = $hasMarker
  }
  diagnostics = [pscustomobject]@{
    target = $target
    sample = if($content){ $content.Substring(0,[Math]::Min(180,$content.Length)) } else { '' }
  }
}

$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("NOTEPAD_L1_VERIFY_REPORT=" + $outPath)
Write-Output ("NOTEPAD_L1_VERIFY_OK=" + $ok)
if (-not $ok) { exit 71 }
exit 0
