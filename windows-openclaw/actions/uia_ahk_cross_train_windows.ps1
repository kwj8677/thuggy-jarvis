param(
  [ValidateSet('explorer','settings')]
  [string]$App = 'explorer',
  [int]$MaxCandidates = 60
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-uia-ahk-cross-train-$App.json")

function Get-AhkExe {
  foreach($p in @(
    'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe',
    'C:\Program Files\AutoHotkey\AutoHotkey64.exe',
    'C:\Program Files\AutoHotkey\v2\AutoHotkey.exe',
    'C:\Program Files\AutoHotkey\AutoHotkey.exe'
  )) { if(Test-Path $p){ return $p } }
  return $null
}

if($App -eq 'explorer'){
  Start-Process explorer.exe | Out-Null
  Start-Sleep -Milliseconds 800
  $proc = Get-Process explorer -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  $exeArg = 'explorer.exe'
} else {
  Start-Process 'ms-settings:' | Out-Null
  Start-Sleep -Milliseconds 1200
  $proc = Get-Process SystemSettings -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if(-not $proc){ $proc = Get-Process ApplicationFrameHost -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 }
  $exeArg = 'SystemSettings.exe'
}
if(-not $proc){ throw "${App}_window_not_found" }

$root = [System.Windows.Automation.AutomationElement]::FromHandle($proc.MainWindowHandle)
if(-not $root){ throw "${App}_root_not_found" }

$types = @([System.Windows.Automation.ControlType]::Button, [System.Windows.Automation.ControlType]::TabItem)
$candidates = New-Object System.Collections.Generic.List[object]
$deadline = (Get-Date).AddSeconds(8)
$scope = if($App -eq 'settings'){ [System.Windows.Automation.TreeScope]::Children } else { [System.Windows.Automation.TreeScope]::Descendants }
foreach($t in $types){
  if((Get-Date) -gt $deadline){ break }
  $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, $t)
  $all = $root.FindAll($scope, $cond)
  for($i=0; $i -lt $all.Count; $i++){
    if((Get-Date) -gt $deadline){ break }
    $el = $all.Item($i); $name=[string]$el.Current.Name; $r=$el.Current.BoundingRectangle
    if([string]::IsNullOrWhiteSpace($name)){ continue }
    if($name.Length -gt 80){ continue }
    if($name -match '닫기|Close|최소화|최대화|Minimize|Maximize|뒤로|Back|검색'){ continue }
    if(-not $el.Current.IsEnabled){ continue }
    if($r.Width -lt 20 -or $r.Height -lt 20){ continue }
    if($r.Left -lt 0 -or $r.Top -lt 0){ continue }
    if($r.Right -gt [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width){ continue }
    if($r.Bottom -gt [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height){ continue }
    $candidates.Add([pscustomobject]@{name=$name;controlType=$el.Current.ControlType.ProgrammaticName;x=[int]($r.Left+$r.Width/2);y=[int]($r.Top+$r.Height/2)})
    if($candidates.Count -ge $MaxCandidates){ break }
  }
  if($candidates.Count -ge $MaxCandidates){ break }
}
if($candidates.Count -lt 1){
  # relaxed fallback for settings: try descendants quickly
  if($App -eq 'settings'){
    foreach($t in $types){
      $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, $t)
      $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
      for($i=0; $i -lt [Math]::Min($all.Count,40); $i++){
        $el=$all.Item($i); $name=[string]$el.Current.Name; $r=$el.Current.BoundingRectangle
        if([string]::IsNullOrWhiteSpace($name)){ continue }
        if(-not $el.Current.IsEnabled){ continue }
        if($r.Width -lt 20 -or $r.Height -lt 20){ continue }
        $candidates.Add([pscustomobject]@{name=$name;controlType=$el.Current.ControlType.ProgrammaticName;x=[int]($r.Left+$r.Width/2);y=[int]($r.Top+$r.Height/2)})
      }
      if($candidates.Count -gt 0){ break }
    }
  }
}
if($candidates.Count -lt 1){ throw 'no_candidates' }
$target = Get-Random -InputObject $candidates

$ahk = Get-AhkExe
if(-not $ahk){ throw 'ahk_not_installed' }
$ahkScript = 'C:\openclaw\actions\gui_click_engine.ahk'
$proc2 = Start-Process -FilePath $ahk -ArgumentList @($ahkScript,$exeArg,[string]$target.x,[string]$target.y) -PassThru -Wait -WindowStyle Hidden
$ahkExit = $proc2.ExitCode

$hitMatched=$false; $focusMatched=$false; $hitName=''; $focusName=''
$token=$target.name; if($token.Length -gt 10){ $token=$token.Substring(0,10) }
foreach($d in @(180,520)){
  Start-Sleep -Milliseconds $d
  $pt = New-Object System.Windows.Point($target.x,$target.y)
  $hit=[System.Windows.Automation.AutomationElement]::FromPoint($pt)
  $hitName=if($hit){[string]$hit.Current.Name}else{''}
  $focused=[System.Windows.Automation.AutomationElement]::FocusedElement
  $focusName=if($focused){[string]$focused.Current.Name}else{''}
  $hitMatched = $hitMatched -or ($hitName -eq $target.name)
  if($token){ $focusMatched = $focusMatched -or ($focusName -like ("*"+$token+"*")) }
  if($hitMatched -or $focusMatched){ break }
}

$ok = ($ahkExit -eq 0) -and ($hitMatched -or $focusMatched)
$result=[pscustomobject]@{ok=$ok;runId=$runId;app=$App;target=$target;checks=[pscustomobject]@{ahkExit=$ahkExit;hitMatched=$hitMatched;focusMatched=$focusMatched;hitName=$hitName;focusName=$focusName}}
$result|ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("UIA_AHK_CROSS_TRAIN_WINDOWS_REPORT="+$outPath)
Write-Output ("UIA_AHK_CROSS_TRAIN_WINDOWS_OK="+$ok)
if(-not $ok){ exit 75 }
exit 0
