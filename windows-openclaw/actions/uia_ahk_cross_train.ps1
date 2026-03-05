param(
  [int]$MaxCandidates = 80
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outPath = Join-Path $logDir ("$runId-uia-ahk-cross-train.json")

function Get-AhkExe {
  $candidates = @(
    'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe',
    'C:\Program Files\AutoHotkey\AutoHotkey64.exe',
    'C:\Program Files\AutoHotkey\v2\AutoHotkey.exe',
    'C:\Program Files\AutoHotkey\AutoHotkey.exe'
  )
  foreach($p in $candidates){ if(Test-Path $p){ return $p } }
  return $null
}

# Ensure chrome visible (best effort)
try { & 'C:\openclaw\run.ps1' -Action 'chrome_uia_pipeline.ps1' -TimeoutSec 120 | Out-Null } catch {}

$chrome = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if(-not $chrome){ throw 'chrome_window_not_found' }

$root = [System.Windows.Automation.AutomationElement]::FromHandle($chrome.MainWindowHandle)
if(-not $root){ throw 'chrome_root_not_found' }

$allowedTypes = @(
  [System.Windows.Automation.ControlType]::Button,
  [System.Windows.Automation.ControlType]::TabItem
)

$candidates = New-Object System.Collections.Generic.List[object]
foreach($t in $allowedTypes){
  $cond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty, $t
  )
  $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
  for($i=0; $i -lt $all.Count; $i++){
    $el = $all.Item($i)
    $name = [string]$el.Current.Name
    $rect = $el.Current.BoundingRectangle
    if([string]::IsNullOrWhiteSpace($name)){ continue }
    if($name.Length -gt 80){ continue }
    if($name -match '닫기|Close|최소화|최대화|Minimize|Maximize|주소창|Address'){ continue }
    if($name -match 'OpenClaw Browser Relay'){ continue }
    if($name -match '검색모드|통합검색|프로필|내 정보|정보 보기'){ continue }
    if(-not $el.Current.IsEnabled){ continue }
    if(-not $el.Current.IsKeyboardFocusable){ continue }
    if($rect.Width -lt 20 -or $rect.Height -lt 20){ continue }
    if($rect.Left -lt 0 -or $rect.Top -lt 0){ continue }
    if($rect.Right -gt [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width){ continue }
    if($rect.Bottom -gt [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height){ continue }
    $cx = [int]($rect.Left + $rect.Width/2)
    $cy = [int]($rect.Top + $rect.Height/2)
    $candidates.Add([pscustomobject]@{
      name=$name; controlType=$el.Current.ControlType.ProgrammaticName; x=$cx; y=$cy; w=[int]$rect.Width; h=[int]$rect.Height
    })
    if($candidates.Count -ge $MaxCandidates){ break }
  }
  if($candidates.Count -ge $MaxCandidates){ break }
}

if($candidates.Count -lt 1){ throw 'no_clickable_candidates' }

$target = Get-Random -InputObject $candidates

$ahk = Get-AhkExe
if(-not $ahk){ throw 'ahk_not_installed' }
$ahkScript = 'C:\openclaw\actions\gui_click_engine.ahk'
if(-not (Test-Path $ahkScript)){ throw 'gui_click_engine_missing' }

$proc = Start-Process -FilePath $ahk -ArgumentList @($ahkScript,'chrome',[string]$target.x,[string]$target.y) -PassThru -Wait -WindowStyle Hidden
$ahkExit = $proc.ExitCode

# two-phase verification (timing-sensitive UI)
$hitMatched = $false
$focusMatched = $false
$popupChanged = $false
$hitName = ''
$hitType = ''
$focusName = ''

$token = $target.name
if($token.Length -gt 10){ $token = $token.Substring(0,10) }

foreach($delay in @(180, 520)){
  Start-Sleep -Milliseconds $delay
  $pt = New-Object System.Windows.Point($target.x, $target.y)
  $hit = [System.Windows.Automation.AutomationElement]::FromPoint($pt)
  $hitName = if($hit){ [string]$hit.Current.Name } else { '' }
  $hitType = if($hit){ [string]$hit.Current.ControlType.ProgrammaticName } else { '' }

  $focused = [System.Windows.Automation.AutomationElement]::FocusedElement
  $focusName = if($focused){ [string]$focused.Current.Name } else { '' }

  if($token){ $focusMatched = $focusMatched -or ($focusName -like ("*"+$token+"*")) }
  $hitMatched = $hitMatched -or ($hitName -eq $target.name)
  $popupChanged = $popupChanged -or ($hitType -match 'ControlType.Document|ControlType.Menu|ControlType.Pane')

  if($hitMatched -or $focusMatched){ break }
}

$ok = ($ahkExit -eq 0) -and ($hitMatched -or $focusMatched -or $popupChanged)

$result = [pscustomobject]@{
  ok = $ok
  runId = $runId
  timestamp = $now.ToString('o')
  target = $target
  checks = [pscustomobject]@{
    ahkExit = $ahkExit
    hitMatched = $hitMatched
    focusMatched = $focusMatched
    popupChanged = $popupChanged
    hitName = $hitName
    hitType = $hitType
    focusName = $focusName
  }
}

$result | ConvertTo-Json -Depth 8 | Out-File -FilePath $outPath -Encoding utf8
Write-Output ("UIA_AHK_CROSS_TRAIN_REPORT=" + $outPath)
Write-Output ("UIA_AHK_CROSS_TRAIN_OK=" + $ok)
if(-not $ok){ exit 74 }
exit 0
