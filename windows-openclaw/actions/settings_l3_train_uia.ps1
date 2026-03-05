$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

$runId = (Get-Date).ToString('yyyyMMdd-HHmmss')
$report = "C:\openclaw\logs\$runId-settings-l3-train-uia-report.json"

function Save($ok,$reason,$data){
  [pscustomobject]@{ok=$ok;reason=$reason;timestamp=(Get-Date).ToString('o');data=$data} |
    ConvertTo-Json -Depth 8 | Out-File -FilePath $report -Encoding utf8
  Write-Output ("SETTINGS_L3_TRAIN_UIA_REPORT=" + $report)
}

Start-Process "ms-settings:" | Out-Null

$proc = $null
for($i=0; $i -lt 30; $i++) {
  Start-Sleep -Milliseconds 300
  $proc = @(
    Get-Process SystemSettings -ErrorAction SilentlyContinue
    Get-Process ApplicationFrameHost -ErrorAction SilentlyContinue
  ) | Where-Object { $_ -and $_.MainWindowHandle -ne 0 } |
    Sort-Object StartTime -Descending |
    Select-Object -First 1
  if($proc){ break }
}
if(-not $proc){ Save $false 'no_visible_settings' @{}; exit 301 }

$root = [System.Windows.Automation.AutomationElement]::FromHandle($proc.MainWindowHandle)
if(-not $root){ Save $false 'no_uia_root' @{pid=$proc.Id}; exit 302 }

$condEdit = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
  [System.Windows.Automation.ControlType]::Edit
)
$edits = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condEdit)

$search = $null
for($i=0;$i -lt $edits.Count;$i++){
  $name = [string]$edits.Item($i).Current.Name
  if($name -match '검색|Search') { $search = $edits.Item($i); break }
}
if(-not $search -and $edits.Count -gt 0){ $search = $edits.Item(0) }
if(-not $search){ Save $false 'search_box_not_found' @{editCount=$edits.Count}; exit 303 }

$query = '디스플레이'
$vp=$null
if($search.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern,[ref]$vp)){
  $vp.SetValue($query)
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
} else {
  $search.SetFocus()
  Start-Sleep -Milliseconds 80
  [System.Windows.Forms.SendKeys]::SendWait('^a')
  Start-Sleep -Milliseconds 60
  [System.Windows.Forms.SendKeys]::SendWait($query)
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
}
Start-Sleep -Milliseconds 800

$title = $proc.MainWindowTitle
$ok = ($title -match '설정|Settings')
$reason='navigation_not_verified'
if($ok){ $reason='ok' }
Save $ok $reason @{pid=$proc.Id; title=$title; query=$query; editCount=$edits.Count}
if(-not $ok){ exit 304 }
exit 0
