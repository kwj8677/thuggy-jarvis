param(
  [string]$Url = "https://example.com"
)
$ErrorActionPreference='Stop'

agent-browser open $Url | Out-Null
Start-Sleep -Milliseconds 700
$out = agent-browser snapshot -i
$out | Out-File -FilePath "C:\openclaw\logs\agent-browser-snapshot.log" -Encoding utf8
Write-Output "AGENT_BROWSER_SNAPSHOT_OK"
