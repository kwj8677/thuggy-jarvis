param(
  [string]$StartUrl = 'https://blog.naver.com',
  [string]$UserDataDir = 'C:\Users\humil\AppData\Local\Google\Chrome\User Data',
  [string]$ProfileDirectory = 'Default'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$args = @(
  "--remote-debugging-address=127.0.0.1",
  "--remote-debugging-port=9222",
  ('--user-data-dir="' + $UserDataDir + '"'),
  ('--profile-directory="' + $ProfileDirectory + '"'),
  "--new-window",
  $StartUrl
)

Start-Process chrome -ArgumentList $args | Out-Null

$ok = $false
$detail = ''
for($i=0; $i -lt 25; $i++) {
  Start-Sleep -Milliseconds 400
  $p = Get-Process chrome -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Sort-Object StartTime -Descending |
    Select-Object -First 1
  if($p) {
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
    if($root) {
      $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" | Select-Object -First 1 -ExpandProperty CommandLine)
      $profileOk = ([string]$cmd -match [regex]::Escape($UserDataDir)) -and ([string]$cmd -match '--profile-directory=Default')
      if(-not $profileOk){
        Write-Output ("CHROME_L1_LAUNCH_UIA_FAIL wrong_profile pid=" + $p.Id)
        exit 112
      }
      $ok = $true
      $detail = "pid=$($p.Id) title=$($p.MainWindowTitle)"
      break
    }
  }
}

if($ok){
  Write-Output "CHROME_L1_LAUNCH_UIA_OK $detail"
  exit 0
}

Write-Output 'CHROME_L1_LAUNCH_UIA_FAIL no_visible_uia_window'
exit 111
