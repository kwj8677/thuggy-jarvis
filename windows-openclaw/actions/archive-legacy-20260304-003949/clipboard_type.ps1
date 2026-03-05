param([Parameter(Mandatory=$true)][string]$Text)
$ErrorActionPreference='Stop'
Set-Clipboard -Value $Text
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('^v')
Start-Sleep -Milliseconds 100
Write-Output 'CLIPBOARD_PASTED'
