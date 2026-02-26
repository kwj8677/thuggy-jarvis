param(
  [Parameter(Mandatory=$true)][string]$Token,
  [string]$GatewayHost = "127.0.0.1",
  [int]$Port = 18789
)

$ErrorActionPreference = 'Stop'

# 1) Stop existing node-run processes (Windows side only)
Get-CimInstance Win32_Process |
  Where-Object { $_.CommandLine -like '*openclaw node run*' } |
  ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop } catch {}
  }

# 2) Align Windows OpenClaw token settings to WSL gateway token
openclaw config set gateway.auth.token $Token | Out-Null
openclaw config set gateway.remote.token $Token | Out-Null
openclaw config set gateway.remote.url "ws://${GatewayHost}:$Port" | Out-Null

# 3) Launch node host in background with explicit env token
$cmd = "$env:OPENCLAW_GATEWAY_TOKEN='$Token'; openclaw node run --host $GatewayHost --port $Port"
Start-Process -WindowStyle Hidden powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $cmd"

Write-Output "WIN_NODE_SYNC_STARTED"
