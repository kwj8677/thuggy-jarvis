$ErrorActionPreference = 'Stop'

# 1) Policy restore
New-Item -Path 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Force | Out-Null
New-Item -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome' -Force | Out-Null
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Name 'RemoteDebuggingAllowed' -Type DWord -Value 1
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome' -Name 'RemoteDebuggingAllowed' -Type DWord -Value 1

$extId = 'fnmkpinjlflhfciolcncjeajkjgldghn'
$extJson = @{ "$extId" = @{ runtime_allowed_hosts = @('*://*/*') } } | ConvertTo-Json -Compress -Depth 5
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Google\Chrome' -Name 'ExtensionSettings' -Type String -Value $extJson
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Google\Chrome' -Name 'ExtensionSettings' -Type String -Value $extJson

# 2) force command template overwrite
$cmdPath = 'C:\openclaw\actions\launch_chrome_visible.cmd'
@'
@echo off
start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 --user-data-dir="C:\Users\humil\AppData\Local\Google\Chrome\User Data" --profile-directory="Default" --new-window https://www.google.com
'@ | Out-File -FilePath $cmdPath -Encoding ascii -Force

# 3) interactive launch via task
$task = 'OpenClaw_ChromeInteractive'
$user = $env:USERNAME
schtasks /Delete /TN $task /F 2>$null | Out-Null
schtasks /Create /TN $task /TR $cmdPath /SC ONLOGON /RU $user /IT /F | Out-Null
schtasks /Run /TN $task | Out-Null
Start-Sleep -Seconds 4

# 4) CDP health (retry)
$cdpOk = $false
for ($i=0; $i -lt 3; $i++) {
  try {
    $v = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:9222/json/version' -TimeoutSec 3
    if ($v.StatusCode -eq 200) { $cdpOk = $true; break }
  } catch {}
  Start-Sleep -Seconds 1
}

# 5) visible window
$win = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 3 Id,MainWindowTitle,MainWindowHandle

Write-Output "REMEDIATE_DONE"
Write-Output ("CDP_OK=" + $cdpOk)
if ($win) { $win | Format-Table -AutoSize }

if (-not $cdpOk) { exit 41 }
if (-not $win) { exit 42 }
exit 0
