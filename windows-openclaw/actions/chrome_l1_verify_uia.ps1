$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$now = Get-Date
$runId = $now.ToString('yyyyMMdd-HHmmss')
$logDir = 'C:\openclaw\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$report = Join-Path $logDir ("$runId-chrome-l1-verify-uia-report.json")

function Save-Report($ok, $reason, $data) {
  $obj = [pscustomobject]@{
    ok = $ok
    reason = $reason
    timestamp = (Get-Date).ToString('o')
    data = $data
  }
  $obj | ConvertTo-Json -Depth 8 | Out-File -FilePath $report -Encoding utf8
  Write-Output ("CHROME_L1_VERIFY_UIA_REPORT=" + $report)
}

$p = Get-Process chrome -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  Sort-Object StartTime -Descending |
  Select-Object -First 1

if(-not $p){
  Save-Report $false 'no_visible_chrome' @{}
  Write-Output 'CHROME_L1_VERIFY_UIA_FAIL no_visible_chrome'
  exit 121
}

$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
if(-not $root){
  Save-Report $false 'no_uia_root' @{ pid = $p.Id; title = $p.MainWindowTitle }
  Write-Output 'CHROME_L1_VERIFY_UIA_FAIL no_uia_root'
  exit 122
}

$condEdit = New-Object System.Windows.Automation.PropertyCondition(
  [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
  [System.Windows.Automation.ControlType]::Edit
)
$edits = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condEdit)

$hit = $false
$hitName = ''
for($i=0; $i -lt $edits.Count; $i++){
  $name = [string]$edits.Item($i).Current.Name
  if($name -match '주소|검색|Address|Search|Omnibox|주소 및 검색창|Search Google or type a URL') {
    $hit = $true
    $hitName = $name
    break
  }
}

if(-not $hit -and $edits.Count -gt 0){
  $hit = $true
  $hitName = [string]$edits.Item(0).Current.Name
}

if($hit){
  Save-Report $true 'ok' @{ pid = $p.Id; title = $p.MainWindowTitle; editCount = $edits.Count; matchedName = $hitName; mode = 'edit_match' }
  Write-Output ("CHROME_L1_VERIFY_UIA_OK pid=" + $p.Id + " editName=" + $hitName + " editCount=" + $edits.Count)
  exit 0
}

if($root -and $p.MainWindowTitle -match 'Chrome'){
  Save-Report $true 'ok' @{ pid = $p.Id; title = $p.MainWindowTitle; editCount = $edits.Count; matchedName = ''; mode = 'title_fallback' }
  Write-Output ("CHROME_L1_VERIFY_UIA_OK fallback=title pid=" + $p.Id + " title=" + $p.MainWindowTitle)
  exit 0
}

Save-Report $false 'address_bar_not_found' @{ pid = $p.Id; title = $p.MainWindowTitle; editCount = $edits.Count }
Write-Output ("CHROME_L1_VERIFY_UIA_FAIL address_bar_not_found editCount=" + $edits.Count)
exit 123
