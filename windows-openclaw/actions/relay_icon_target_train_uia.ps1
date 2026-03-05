$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MouseOps {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
  public const uint LEFTDOWN = 0x0002;
  public const uint LEFTUP = 0x0004;
}
"@

$runId = (Get-Date).ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$report = Join-Path $logDir ("$runId-relay-icon-target-train-uia-report.json")

function Save($ok,$reason,$data){
  [pscustomobject]@{ok=$ok;reason=$reason;timestamp=(Get-Date).ToString('o');data=$data} |
    ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 -FilePath $report
  Write-Output ("RELAY_ICON_TARGET_TRAIN_UIA_REPORT=" + $report)
}

$p = Get-Process chrome -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  Sort-Object StartTime -Descending | Select-Object -First 1
if(-not $p){ Save $false 'no_visible_chrome' @{}; exit 171 }

$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
if(-not $root){ Save $false 'no_uia_root' @{pid=$p.Id;title=$p.MainWindowTitle}; exit 172 }

$btnCond = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
  [System.Windows.Automation.ControlType]::Button
)
$buttons = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)

$target = $null
$targetName = ''
for($i=0; $i -lt $buttons.Count; $i++){
  $b = $buttons.Item($i)
  $n = [string]$b.Current.Name
  if($n -match 'OpenClaw Browser Relay|OpenClaw|Browser Relay|Relay'){
    $target = $b
    $targetName = $n
    break
  }
}
if(-not $target){ Save $false 'target_not_found' @{pid=$p.Id;title=$p.MainWindowTitle;buttonCount=$buttons.Count}; exit 173 }

$inv = $null
if($target.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$inv)){
  $inv.Invoke()
  Start-Sleep -Milliseconds 700
  Save $true 'ok_invoke' @{pid=$p.Id;title=$p.MainWindowTitle;targetName=$targetName;buttonCount=$buttons.Count;method='invoke'}
  exit 0
}

$rect = $target.Current.BoundingRectangle
if($rect.Width -le 0 -or $rect.Height -le 0){
  Save $false 'no_clickable_rect' @{pid=$p.Id;title=$p.MainWindowTitle;targetName=$targetName;buttonCount=$buttons.Count}
  exit 174
}
$x = [int]($rect.Left + ($rect.Width/2))
$y = [int]($rect.Top + ($rect.Height/2))
[MouseOps]::SetCursorPos($x,$y) | Out-Null
Start-Sleep -Milliseconds 80
[MouseOps]::mouse_event([MouseOps]::LEFTDOWN,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 40
[MouseOps]::mouse_event([MouseOps]::LEFTUP,0,0,0,[UIntPtr]::Zero)
Start-Sleep -Milliseconds 700

Save $true 'ok_click_fallback' @{pid=$p.Id;title=$p.MainWindowTitle;targetName=$targetName;buttonCount=$buttons.Count;method='mouse_click';x=$x;y=$y}
exit 0
