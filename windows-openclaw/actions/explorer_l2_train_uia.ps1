param(
  [string]$TargetPath = 'C:\openclaw\logs'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

$runId = (Get-Date).ToString('yyyyMMdd-HHmmss')
$report = "C:\openclaw\logs\$runId-explorer-l2-train-uia-report.json"

function Save($ok,$reason,$data){
  [pscustomobject]@{ok=$ok;reason=$reason;timestamp=(Get-Date).ToString('o');data=$data} |
    ConvertTo-Json -Depth 8 | Out-File -FilePath $report -Encoding utf8
  Write-Output ("EXPLORER_L2_TRAIN_UIA_REPORT=" + $report)
}

Start-Process explorer.exe $TargetPath | Out-Null
Start-Sleep -Milliseconds 1200

$proc = Get-Process explorer -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  Sort-Object StartTime -Descending |
  Select-Object -First 1
if(-not $proc){ Save $false 'no_visible_explorer' @{}; exit 201 }

$root = [System.Windows.Automation.AutomationElement]::FromHandle($proc.MainWindowHandle)
if(-not $root){ Save $false 'no_uia_root' @{pid=$proc.Id}; exit 202 }

$condEdit = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
  [System.Windows.Automation.ControlType]::Edit
)
$edits = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condEdit)

$address = $null
for($i=0;$i -lt $edits.Count;$i++){
  $name = [string]$edits.Item($i).Current.Name
  if($name -match '주소|Address|주소 표시줄|Address bar|검색|Search') { $address = $edits.Item($i); break }
}

# fallback strategy: force focus to address bar and type
if(-not $address){
  [System.Windows.Forms.SendKeys]::SendWait('^l')
  Start-Sleep -Milliseconds 120
  [System.Windows.Forms.SendKeys]::SendWait($TargetPath)
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
} else {
  $vp=$null
  if($address.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern,[ref]$vp)){
    $vp.SetValue($TargetPath)
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
  } else {
    $address.SetFocus()
    Start-Sleep -Milliseconds 80
    [System.Windows.Forms.SendKeys]::SendWait('^l')
    Start-Sleep -Milliseconds 80
    [System.Windows.Forms.SendKeys]::SendWait($TargetPath)
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
  }
}
Start-Sleep -Milliseconds 650

$title = $proc.MainWindowTitle
$ok = ($title -match 'logs|로그|openclaw|C:\\openclaw')
$reason = 'path_change_not_verified'
if($ok){ $reason = 'ok' }
Save $ok $reason @{pid=$proc.Id; title=$title; targetPath=$TargetPath; editCount=$edits.Count; usedFallback=([bool](-not $address))}
if(-not $ok){ exit 204 }
exit 0
