param(
  [int]$AttemptIndex = 0,
  [string]$Profile = "chrome"
)

$ErrorActionPreference = 'Stop'
$calibPath = 'C:\openclaw\relay-calibration.json'
$learnPath = 'C:\openclaw\relay-learn.json'

if (-not (Get-Process chrome -ErrorAction SilentlyContinue)) {
  Start-Process chrome
  Start-Sleep -Seconds 2
}

# Window metrics (psw/PowerShell side)
$chrome = Get-Process chrome -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $chrome) { Write-Output 'NO_CHROME'; exit 2 }

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
"@

$rect = New-Object Win32+RECT
[Win32]::GetWindowRect($chrome.MainWindowHandle, [ref]$rect) | Out-Null
$winW = [Math]::Max(0, $rect.Right - $rect.Left)
$winH = [Math]::Max(0, $rect.Bottom - $rect.Top)

# Base candidates from calibration JSON
$candidates = @(
  @{x=235;y=90}, @{x=220;y=90}, @{x=235;y=74}, @{x=205;y=74}, @{x=250;y=74},
  @{x=205;y=90}, @{x=250;y=90}, @{x=190;y=58}, @{x=220;y=58},
  @{x=220;y=48}, @{x=235;y=48}, @{x=205;y=48}
)

if (Test-Path $calibPath) {
  try {
    $j = Get-Content $calibPath -Raw | ConvertFrom-Json
    if ($j.chrome.iconCandidates) {
      $fromJson = @()
      foreach($p in $j.chrome.iconCandidates){
        if($p.xOffsetFromRight -and $p.y){ $fromJson += @{x=[int]$p.xOffsetFromRight;y=[int]$p.y} }
      }
      if($fromJson.Count -gt 0){ $candidates = $fromJson + $candidates }
    }
  } catch {}
}

# Lightweight learning priority (success score)
$score = @{}
if (Test-Path $learnPath) {
  try {
    $lj = Get-Content $learnPath -Raw | ConvertFrom-Json
    if ($lj.points) {
      foreach($k in $lj.points.PSObject.Properties.Name){ $score[$k] = [int]$lj.points.$k }
    }
  } catch {}
}

$uniq = @{}
$ordered = @()
foreach($c in $candidates){
  $k = "$($c.x),$($c.y)"
  if (-not $uniq.ContainsKey($k)) { $uniq[$k]=$true; $ordered += $c }
}

$ordered = $ordered | Sort-Object -Property @{Expression={
  $k = "$($_.x),$($_.y)"
  if ($score.ContainsKey($k)) { -1 * $score[$k] } else { 0 }
}}, @{Expression={$_.y}}, @{Expression={$_.x}}

$idx = [Math]::Abs($AttemptIndex) % $ordered.Count
$pick = $ordered[$idx]

# Sanity clamp by current window (avoid nonsense)
if ($pick.y -lt 20) { $pick.y = 20 }
if ($pick.y -gt [Math]::Min(140, [Math]::Max(40, $winH-20))) { $pick.y = 90 }
if ($pick.x -lt 60) { $pick.x = 120 }
if ($pick.x -gt [Math]::Max(320, [Math]::Floor($winW*0.8))) { $pick.x = 220 }

$arg = "$($pick.x) $($pick.y)"
& C:\openclaw\run.ps1 -Action relay_click_window_offset_safe.ahk -ActionArgs $arg -TimeoutSec 8 | Out-Null
$rc = $LASTEXITCODE

Write-Output "CLICK_SENT profile=$Profile xoff=$($pick.x) y=$($pick.y) rc=$rc idx=$AttemptIndex win=${winW}x${winH}"
exit $rc
