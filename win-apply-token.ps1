param(
  [Parameter(Mandatory=$true)][string]$Token
)

$ErrorActionPreference = 'Stop'

openclaw config set gateway.auth.token $Token | Out-Null
openclaw config set gateway.remote.token $Token | Out-Null
openclaw config set gateway.remote.url ws://127.0.0.1:18789 | Out-Null

$h = [System.BitConverter]::ToString((New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Token))).Replace('-','').ToLower()
Write-Output "APPLIED_TOKEN_SHA256=$h"

$rh = (openclaw config get gateway.remote.token).Trim()
$rah = [System.BitConverter]::ToString((New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($rh))).Replace('-','').ToLower()
Write-Output "WIN_REMOTE_SHA256=$rah"
