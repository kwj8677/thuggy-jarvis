$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$report = Join-Path $logDir ("$runId-relay-attach-uia-report.json")

function Save-Report($ok, $reason, $data) {
  [pscustomobject]@{ ok=$ok; reason=$reason; timestamp=(Get-Date).ToString('o'); data=$data } |
    ConvertTo-Json -Depth 10 | Out-File -FilePath $report -Encoding utf8
  Write-Output ("RELAY_ATTACH_UIA_REPORT=" + $report)
}

function Invoke-IconTargetFallback {
  $fallbackScript = Join-Path $PSScriptRoot 'relay_icon_target_train_uia.ps1'
  if(-not (Test-Path $fallbackScript)){ return $false }
  $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy','Bypass',
    '-File', $fallbackScript
  ) -NoNewWindow -Wait -PassThru
  return ($proc.ExitCode -eq 0)
}

$p = Get-Process chrome -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  Sort-Object StartTime -Descending |
  Select-Object -First 1
if(-not $p){ Save-Report $false 'no_visible_chrome' @{}; exit 151 }

$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
if(-not $root){ Save-Report $false 'no_uia_root' @{ pid=$p.Id; title=$p.MainWindowTitle }; exit 152 }

$btnCond = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
  [System.Windows.Automation.ControlType]::Button
)
$buttons = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
$btnCount = $buttons.Count

$explicit = New-Object System.Collections.Generic.List[object]
for($i=0; $i -lt $buttons.Count; $i++){
  $b = $buttons.Item($i)
  $name = [string]$b.Current.Name
  if($name -match 'OpenClaw|Relay|Browser Relay|확장 프로그램|Extensions|확장') {
    $explicit.Add([pscustomobject]@{el=$b;name=$name;source='name_match'}) | Out-Null
  }
}

$heur = New-Object System.Collections.Generic.List[object]
$tbCond = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
  [System.Windows.Automation.ControlType]::ToolBar
)
$toolbars = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $tbCond)
for($i=0; $i -lt $toolbars.Count; $i++){
  $tb = $toolbars.Item($i)
  $tbName = [string]$tb.Current.Name
  $tbBtns = $tb.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
  if($tbBtns.Count -ge 2){
    for($j=0; $j -lt $tbBtns.Count; $j++){
      $b = $tbBtns.Item($j)
      $name = [string]$b.Current.Name
      if($name -match '확장|Extensions|확장 프로그램|브라우저' -or [string]::IsNullOrWhiteSpace($name)){
        $heur.Add([pscustomobject]@{el=$b;name=$name;source=('toolbar:'+ $tbName)}) | Out-Null
      }
    }
  }
}

$all = @()
$all += $explicit
$all += $heur

if($all.Count -eq 0){
  if(Invoke-IconTargetFallback){
    Save-Report $true 'ok_via_icon_target_fallback' @{ pid=$p.Id; title=$p.MainWindowTitle; buttonCount=$btnCount; explicitMatchCount=$explicit.Count; heuristicCount=$heur.Count; fallbackFrom='no_match' }
    exit 0
  }
  Save-Report $false 'no_match' @{ pid=$p.Id; title=$p.MainWindowTitle; buttonCount=$btnCount; explicitMatchCount=$explicit.Count; heuristicCount=$heur.Count }
  exit 153
}

$target = $all[0]
$inv = $null
if($target.el.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$inv)){
  $inv.Invoke()
  Start-Sleep -Milliseconds 900
  Save-Report $true 'ok' @{ pid=$p.Id; title=$p.MainWindowTitle; buttonCount=$btnCount; explicitMatchCount=$explicit.Count; heuristicCount=$heur.Count; targetName=[string]$target.name; source=[string]$target.source; invoked=$true }
  exit 0
}

$altInvoked = $false
$altInvokePath = $null
$legacy = $null
try {
  $legacyPattern = $null
  $legacyTypeNames = @(
    'System.Windows.Automation.LegacyIAccessiblePattern, UIAutomationClient',
    'System.Windows.Automation.LegacyIAccessiblePatternIdentifiers, UIAutomationClient'
  )
  foreach($typeName in $legacyTypeNames){
    $t = [Type]::GetType($typeName, $false)
    if($t){
      $p = $t.GetProperty('Pattern')
      if($p){
        $legacyPattern = $p.GetValue($null)
        break
      }
    }
  }
  if($legacyPattern -and $target.el.TryGetCurrentPattern($legacyPattern, [ref]$legacy) -and $legacy){
    $m = $legacy.GetType().GetMethod('DoDefaultAction')
    if($m){
      $m.Invoke($legacy, $null) | Out-Null
      $altInvoked = $true
      $altInvokePath = 'legacy_default_action'
    }
  }
} catch {}
if(-not $altInvoked){
  try {
    $rect = $target.el.Current.BoundingRectangle
    if($rect.Width -gt 1 -and $rect.Height -gt 1){
      Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class UiaMouseNative {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
}
"@ -ErrorAction SilentlyContinue
      $cx = [int]($rect.X + ($rect.Width / 2))
      $cy = [int]($rect.Y + ($rect.Height / 2))
      [UiaMouseNative]::SetCursorPos($cx, $cy) | Out-Null
      [UiaMouseNative]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
      Start-Sleep -Milliseconds 50
      [UiaMouseNative]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
      $altInvoked = $true
      $altInvokePath = 'coordinate_click'
    }
  } catch {}
}
if($altInvoked){
  Start-Sleep -Milliseconds 900
  Save-Report $true 'ok' @{ pid=$p.Id; title=$p.MainWindowTitle; buttonCount=$btnCount; explicitMatchCount=$explicit.Count; heuristicCount=$heur.Count; targetName=[string]$target.name; source=[string]$target.source; invoked=$true; invokePath=$altInvokePath }
  exit 0
}

if(Invoke-IconTargetFallback){
  Save-Report $true 'ok_via_icon_target_fallback' @{ pid=$p.Id; title=$p.MainWindowTitle; buttonCount=$btnCount; explicitMatchCount=$explicit.Count; heuristicCount=$heur.Count; targetName=[string]$target.name; source=[string]$target.source; invoked=$false; fallbackFrom='invoke_missing' }
  exit 0
}

Save-Report $false 'invoke_missing' @{ pid=$p.Id; title=$p.MainWindowTitle; buttonCount=$btnCount; explicitMatchCount=$explicit.Count; heuristicCount=$heur.Count; targetName=[string]$target.name; source=[string]$target.source; invoked=$false }
exit 154
