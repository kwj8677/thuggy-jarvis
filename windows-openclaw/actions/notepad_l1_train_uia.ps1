param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

$marker = "L1TRAINMARKER-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
$payload = "$marker`r`nFirst-principles Windows UIA training pass.`r`n"

# deterministic start
Get-Process notepad -ErrorAction SilentlyContinue |
  Where-Object { $_.MainWindowHandle -ne 0 } |
  ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 250

Start-Process notepad.exe | Out-Null

try {
  $proc = $null
  for($i=0; $i -lt 40; $i++) {
    $proc = Get-Process notepad -ErrorAction SilentlyContinue |
      Where-Object { $_.MainWindowHandle -ne 0 } |
      Sort-Object StartTime -Descending |
      Select-Object -First 1
    if ($proc) { break }
    Start-Sleep -Milliseconds 200
  }
  if (-not $proc -or $proc.MainWindowHandle -eq 0) { throw "MainWindowHandle=0" }

  $el = [System.Windows.Automation.AutomationElement]::FromHandle($proc.MainWindowHandle)
  if (-not $el) { throw "AutomationElement null" }

  $condDoc = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Document
  )
  $condEdit = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Edit
  )

  $doc = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condDoc)
  if (-not $doc) { $doc = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condEdit) }
  if (-not $doc) { throw "Editable control not found" }

  $usedPattern = 'none'
  $vp = $null
  if ($doc.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$vp)) {
    $vp.SetValue($payload)
    $usedPattern = 'ValuePattern'
  } else {
    $doc.SetFocus()
    Start-Sleep -Milliseconds 80
    [System.Windows.Forms.SendKeys]::SendWait('^a')
    Start-Sleep -Milliseconds 40
    [System.Windows.Forms.SendKeys]::SendWait($payload)
    $usedPattern = 'SendKeysFallback'
  }

  Start-Sleep -Milliseconds 200

  # read-back verification (state change gate)
  $readback = ''
  if ($doc.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern, [ref]$vp)) {
    $readback = $vp.Current.Value
  } else {
    $readback = ($doc.Current.Name + ' ' + $doc.Current.HelpText)
  }

  $hasMarker = ($readback -like "*${marker}*")

  # close without save
  [System.Windows.Forms.SendKeys]::SendWait('%{F4}')
  Start-Sleep -Milliseconds 120
  [System.Windows.Forms.SendKeys]::SendWait('!n')

  if (-not $hasMarker) { throw "ReadbackMissingMarker" }

  Write-Output ("NOTEPAD_UIA_OK marker=" + $marker + " pattern=" + $usedPattern)
  exit 0
}
catch {
  Write-Output ("NOTEPAD_UIA_FAIL " + $_.Exception.Message)
  exit 72
}
finally {
  try {
    Get-Process notepad -ErrorAction SilentlyContinue |
      Where-Object { $_.MainWindowHandle -ne 0 } |
      ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
  } catch {}
}
