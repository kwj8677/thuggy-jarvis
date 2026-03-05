$ErrorActionPreference = 'Stop'
$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-chrome-uia-pipeline.json")

$steps = @()
function Add-Step($name,$ok,$detail){
  $script:steps += [pscustomobject]@{name=$name; ok=$ok; detail=$detail; ts=(Get-Date).ToString('o')}
}
function Get-VisibleChromeWindow {
  Get-Process chrome -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Sort-Object StartTime -Descending |
    Select-Object -First 1
}

& C:\openclaw\run.ps1 -Action session_gate.ps1 -TimeoutSec 20 | Out-Null
$rc1 = $LASTEXITCODE
Add-Step 'session_gate' ($rc1 -eq 0) ("exitCode=$rc1")
if($rc1 -ne 0){
  $r=[pscustomobject]@{ok=$false;runId=$runId;reason='session_gate_failed';steps=$steps}
  $r|ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
  Write-Output ("CHROME_UIA_PIPELINE_REPORT="+$outPath)
  exit 131
}

& C:\openclaw\run.ps1 -Action chrome_l1_launch_uia.ps1 -TimeoutSec 35 | Out-Null
$rc2 = $LASTEXITCODE
Add-Step 'chrome_l1_launch_uia' ($rc2 -eq 0) ("exitCode=$rc2")
if($rc2 -ne 0){
  $r=[pscustomobject]@{ok=$false;runId=$runId;reason='launch_failed';steps=$steps}
  $r|ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
  Write-Output ("CHROME_UIA_PIPELINE_REPORT="+$outPath)
  exit 132
}

& C:\openclaw\run.ps1 -Action chrome_l1_verify_uia.ps1 -TimeoutSec 20 | Out-Null
$rc3 = $LASTEXITCODE
Add-Step 'chrome_l1_verify_uia' ($rc3 -eq 0) ("exitCode=$rc3")

if($rc3 -ne 0){
  $win = Get-VisibleChromeWindow
  if($win){
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class UiaWin32 {
  [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@ -ErrorAction SilentlyContinue
    [UiaWin32]::ShowWindowAsync([IntPtr]$win.MainWindowHandle, 9) | Out-Null
    [UiaWin32]::SetForegroundWindow([IntPtr]$win.MainWindowHandle) | Out-Null
    Add-Step 'chrome_recover_focus' $true ("pid=$($win.Id)")
    Start-Sleep -Milliseconds 700
    & C:\openclaw\run.ps1 -Action chrome_l1_verify_uia.ps1 -TimeoutSec 20 | Out-Null
    $rc3 = $LASTEXITCODE
    Add-Step 'chrome_l1_verify_uia_retry' ($rc3 -eq 0) ("exitCode=$rc3")
  } else {
    Add-Step 'chrome_recover_focus' $false 'chrome_window_not_found'
  }
}

$ok = ($rc1 -eq 0 -and $rc2 -eq 0 -and $rc3 -eq 0)
$reason = 'ok'
if(-not $ok){
  if($rc1 -ne 0){
    $reason = 'session_gate_failed'
  } elseif(-not (Get-VisibleChromeWindow)){
    $reason = 'chrome_window_not_found'
  } else {
    $reason = 'verify_failed'
  }
}
$r=[pscustomobject]@{ok=$ok;runId=$runId;reason=$reason;steps=$steps}
$r|ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8
Write-Output ("CHROME_UIA_PIPELINE_REPORT="+$outPath)
Write-Output ("CHROME_UIA_PIPELINE_OK="+$ok)
if(-not $ok){ exit 133 }
exit 0
